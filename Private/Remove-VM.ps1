Function Remove-VM {
    [CmdletBinding(DefaultParameterSetName = 'Name', SupportsShouldProcess = $True)]
    param(
        [Parameter(ParameterSetName = 'Id')]
        [Parameter(ParameterSetName = 'Name')]
        [ValidateNotNullOrEmpty()]
        [Alias('CN')]
        [string]$ComputerName = $env:COMPUTERNAME, 
        [Parameter(ParameterSetName = 'Id', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [System.Nullable[guid]]  $Id, 
        [Parameter(ParameterSetName = 'Name', Position = 0, ValueFromPipeline = $true)]
        [Alias('VMName')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name, 
        [Parameter(ParameterSetName = 'ClusterObject', Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [PSTypeName('Microsoft.FailoverClusters.PowerShell.ClusterObject')]
        [ValidateNotNullOrEmpty()]
        [psobject]$ClusterObject,
        [Switch]$Passthru
    )
 
    begin {
 
        Write-Verbose -Message "Starting $($MyInvocation.Mycommand)"  
        Write-Verbose -Message "Using parameter set $($PSCmdlet.ParameterSetName)"
        Try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                $PSBoundParameters['OutBuffer'] = 1
            }
 
            #remove Whatif from Boundparameters since Get-VM doesn't recognize it
            $PSBoundParameters.Remove("WhatIf") | Out-Null
            $PSBoundParameters.Remove("Passthru") | Out-Null
            $PSBoundParameters.Remove("Confirm") | Out-Null
 
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Get-VM', [System.Management.Automation.CommandTypes]::Cmdlet)
            #$scriptCmd = {& $wrappedCmd @PSBoundParameters }
         
            Write-Verbose "Using parameters:"
            Write-verbose ($PSBoundParameters | Out-String)
     
            $ScriptCmd = {
 
                & $wrappedCmd @PSBoundParameters -pv vm | 
                foreach-object -begin {
                    #create a PSSession to the computer
                    Try {
                        Write-Verbose "Creating PSSession to $computername"
                        $mysession = New-PSSession -ComputerName $computername
                        #turn off Hyper-V object caching
                        Write-Verbose "Disabling VMEventing on $computername"
                        Invoke-Command { Disable-VMEventing -Force -confirm:$False } -session $mySession
                    }
                    catch {
                        Throw
                    }
 
                } -process {
             
                    Write-Debug ($vm | Out-String)
 
                    #write the VM to the pipeline if -Passthru was called
                    if ($Passthru) { $vm }
 
                    Invoke-Command -scriptblock {
                        [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'medium')]
                        Param($VM, [string]$VerbosePreference)
                
                        $WhatIfPreference = $using:WhatifPreference
                        $confirmPreference = $using:ConfirmPreference  
                        Write-Verbose "Whatif = $WhatifPreference"
                        Write-Verbose "ConfirmPreference = $ConfirmPreference"
 
                        #set confirm value
                        switch ($confirmPreference) {
                            "high" { $cv = $false }
                            "medium" { $cv = $False }
                            "low" { $cv = $True }
                            Default { $cv = $False }
                        }

                        $State = (Get-VM $VM.name).State
                        if (!($State -eq "Off")) {
                            Stop-VM -Name $VM.name -TurnOff 
                        }
 
                        #remove snapshots first
                        #$VM is the pipelinevariable from the wrapped command
                        Write-Verbose "Testing for snapshots"
                        if (Get-VMSnapshot -VMName $VM.name -ErrorAction SilentlyContinue) {
                            Write-Verbose "Removing existing snapshots"
                            Remove-VMSnapshot -VMName $VM.name -IncludeAllChildSnapshots -Confirm:$cv
                        }
 
                        $disks = $vm.id | Get-VHD 
            
                        if ($disks.Count -eq 0) {
                            $DiskRemove = $True
                        }

                        #remove disks
                        foreach ($disk in $disks) {
                            #the disk path might still reflect a snapshot so clean them up first
                            #This code shouldn't be necessary since we are removing snapshots,
                            #but just in case...
 
                            [regex]$rx = "\.avhd(.?)"
                            if ($disk.path -match $rx) {
                                Write-Verbose "Cleaning up snapshot leftovers"
                                #get a clean version of the file extension
                                $extension = $rx.Matches($disk.path).value.replace("a", "")
 
                                #a regex to find a GUID and file extension
                                [regex]$rx = "_(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}.avhd(.?)"
                                $thePath = $rx.Replace($disk.path, $extension)
                            }
                            else {
                                $thePath = $disk.path
                            }
                            Try {
                                Write-Verbose "Removing $thePath"
                                if (Test-Path $thePath) {
                                    Remove-Item -Path $thePath -ErrorAction Stop -Confirm:$cv
                                }
                                $DiskRemove = $True
                            }
                            Catch {
                                Write-Warning "Failed to remove $thePath"
                                Write-warning $_.exception.message
                                #don't continue removing anything if there was a problem removing the disk file
                                $DiskRemove = $False
                            }
                        }
                        if ($diskRemove) {
                            #remove the VM
                            $VM | ForEach-Object {
                                Write-Verbose "Removing virtual machine $($_.name)"
                                Remove-VM -Name $_.Name -Force -ErrorAction Stop
                            } #foreach
                        } #if disk remove was successful
                        else {
                            Write-Verbose "Aborting virtual machine removal"
                        }
 
                    } -session $mySession -ArgumentList ($vm, $VerbosePreference) -hidecomputername
 
                } -end {
                    #remove PSSession. Ignore -Whatif and always remove it.
                    Write-Verbose "Removing PSSession to $computername"
                    Remove-PSSession -Session $mySession -WhatIf:$false -Confirm:$False
 
                }
 
            } #scriptCMD
 
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        }
        catch {
            if ($ContinueOnError -eq $false) {
                throw
            }
            
        }
    }
 
    process {
        try {
            $steppablePipeline.Process($_)
        }
        catch {
            throw
        }
    }
 
    end {
        try {
            $steppablePipeline.End()
        }
        catch {
            throw
        }
 
        Write-Verbose -Message "Ending $($MyInvocation.Mycommand)"  
    }
 
} 
