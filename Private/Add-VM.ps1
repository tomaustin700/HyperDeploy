function Add-VM {
    Param
    (
        [Parameter(Mandatory)]
        [VM]$VM,
        [Parameter(Mandatory)]
        [HyperVServer]$HyperVServer,
        [DeploymentOptions]$DeploymentOptions,
        [bool]$ContinueOnError

    )

    $rebuildCount = 0

    try {
        
        
        Build-VM -VM $VM -HyperVServer $HyperVServer -DeploymentOptions $DeploymentOptions -ContinueOnError $ContinueOnError
        
        if ($DeploymentOptions -and $DeploymentOptions.StartAfterCreation) {

            Write-Verbose "Starting VM"

            $StartVMParams = @{ 
                Name         = $VM.Name
                ComputerName = $HyperVServer.Name
            }

            Start-VM @StartVMParams

            if ($VM.Provisioning) {
                Setup-VM -VM $VM -HyperVServer $HyperVServer -DeploymentOptions $DeploymentOptions -ContinueOnError $ContinueOnError
            }
        }

    }
    catch {
        if ($ContinueOnError -eq $false) {
            throw
        }
        else {
            Publish-FailureMessage -VMName $VM.Name 
        }
    }

}

function  Setup-VM {
    Param
    (
        [Parameter(Mandatory)]
        [VM]$VM,
        [Parameter(Mandatory)]
        [HyperVServer]$HyperVServer,
        [DeploymentOptions]$DeploymentOptions,
        [bool]$ContinueOnError

    )

    $InitializeVMParams = @{ 
        VM           = $VM
        HyperVServer = $HyperVServer
    }

    try {
        Initialize-VM @InitializeVMParams  
    }
    catch {
        if ($_.Exception.Message -match "REBUILD NEEDED") {
            #VM NEEDS FULL REBUILD DUE TO VALIDATION FAILURES
            $rebuildCount++

            if ($rebuildCount -eq 3) {
                throw "Failed to build $($VM.Name) three times - giving up"
            }
            else {
                Remove-VM  $VM.Name -ComputerName $HyperVServer.Name -ErrorAction Stop
                Build-VM -VM $VM -HyperVServer $HyperVServer -DeploymentOptions $DeploymentOptions -ContinueOnError $ContinueOnError
                
                Write-Verbose "Starting VM"

                $StartVMParams = @{ 
                    Name         = $VM.Name
                    ComputerName = $HyperVServer.Name
                }

                Start-VM @StartVMParams
                Setup-VM -VM $VM -HyperVServer $HyperVServer -DeploymentOptions $DeploymentOptions -ContinueOnError $ContinueOnError
                
            }
        }                
    }
}

function Build-VM {
    Param
    (
        [Parameter(Mandatory)]
        [VM]$VM,
        [Parameter(Mandatory)]
        [HyperVServer]$HyperVServer,
        [DeploymentOptions]$DeploymentOptions,
        [bool]$ContinueOnError

    )

    $NewVMParams = @{ 
        Name               = $VM.Name
        MemoryStartupBytes = [int64][scriptblock]::Create($VM.MemoryStartupBytes).Invoke()[0] 
        ComputerName       = $HyperVServer.Name
    }

    if ($HyperVServer.SwitchName) {
        $NewVMParams.Add("SwitchName", $HyperVServer.SwitchName)
    }

    $SetVMParams = @{ 
        Name               = $VM.Name
        ProcessorCount     = $VM.ProcessorCount
        MemoryMaximumBytes = [int64][scriptblock]::Create($VM.MemoryMaximumBytes).Invoke()[0]  
        ComputerName       = $HyperVServer.Name
        DynamicMemory      = $true
    }

    if ($VM.CheckpointType) {
        $SetVMParams.Add("CheckpointType", $VM.CheckpointType)
    }

    New-VM  @NewVMParams -ErrorAction Stop | out-null
    Set-VM @SetVMParams -ErrorAction Stop | out-null

    if ($HyperVServer.VMHardDiskPath) {

        $diskPath = $HyperVServer.VMHardDiskPath + "\" + $VM.Name

        Invoke-Command -ComputerName $HyperVServer.Name { 
            if (!(Test-Path -Path $using:diskPath)) {
                New-Item -ItemType directory -Path $using:diskPath -Force
            }
        } 
    
        if ($HyperVServer.GoldenImagePath) {
            Write-Verbose "Copying golden image"

            $path = $HyperVServer.GoldenImagePath

            if ($HyperVServer.GoldenImagePath.StartsWith("\\")) {


                $uncCreds = invoke-expression -Command $VM.UNCCredentialScript

                if ($uncCreds -and $uncCreds.GetType().Name -eq 'PSCredential') {

                    Write-Verbose "Golden Image UNC Path detected - setting up credentials"

                    Invoke-Command -ComputerName $HyperVServer.Name -ScriptBlock { Register-PSSessionConfiguration -Name HyperDeploy -RunAsCredential $using:uncCreds -Force }

                    Write-Verbose "Waiting for WinRM service to be ready"

                    Start-Sleep -Seconds 30

                    Write-Verbose "Copying Golden Image"

                    Invoke-Command  -ConfigurationName HyperDeploy -ComputerName $HyperVServer.Name { 
                        $localPath = $using:path

                        $temp = $env:TEMP
                        $extension = $localPath.Split('.')[-1]

                        $tempGI = "$temp\HyperDeployGoldenImage.$extension"
    
                        if (!(Test-Path "filesystem::$localPath")) {
                            throw "$localPath does not exist"
                        
                        }
    
                        if (!(Test-Path $tempGI)) {
                            Write-Verbose "Golden Image Path is UNC, caching locally."
                            Copy-Item "filesystem::$localPath" -Destination $tempGI
                        }
                    
                        Copy-Item $tempGI -Destination "$using:diskPath\Disk.$extension" 
                
                    }
                }
                else {
                    throw "UNCCredentialScript did not return a valid PSCredential object"
                }
            }
            elseif ($HyperVServer.GoldenImagePath.StartsWith("http")) {
                $temp = $env:TEMP
                $extension = $HyperVServer.GoldenImageExtension
                $tempGI = "$temp\HyperDeployGoldenImage.$extension"

                
                Invoke-WebRequest -Uri $HyperVServer.GoldenImagePath -OutFile $tempGI -UseBasicParsing
            } 
            else {
                Invoke-Command   -ComputerName $HyperVServer.Name { 
                    $localPath = $using:path
                    if (!(Test-Path $localPath)) {
                        throw "$localPath does not exist"
                    }

                    $extension = $localPath.Split('.')[-1]

                    Copy-Item $localPath -Destination "$using:diskPath\Disk.$extension"
                }
            }               
        }
        else {
            Invoke-Command   -ComputerName $HyperVServer.Name { 
                $localPath = $using:path
                if (!(Test-Path $localPath)) {
                    throw "$localPath does not exist"
                }

                $extension = $localPath.Split('.')[-1]

                Copy-Item $localPath -Destination "$using:diskPath\Disk.$extension"
            }
        }
    }
    elseif ($VM.NewVMDiskSizeBytes) {

        $NewVHDParams = @{ 
            Path         = "$diskPath\Disk.vhdx"
            SizeBytes    = [int64][scriptblock]::Create($VM.NewVMDiskSizeBytes).Invoke()[0]
            ComputerName = $HyperVServer.Name
        }
        New-VHD @NewVHDParams -ErrorAction Stop
    }

    Invoke-Command  -ComputerName $HyperVServer.Name { 
        $disk = Get-ChildItem -Path $using:diskPath -Filter "Disk.*" -Recurse -Force 
        $name = $using:VM.Name

        $AddVMHardDiskDriveParams = @{ 
            Path   = $disk[0].FullName
            VMName = $name
        }

        Add-VMHardDiskDrive @AddVMHardDiskDriveParams -ErrorAction Stop
    }

}