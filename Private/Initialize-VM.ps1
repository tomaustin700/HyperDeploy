
function Wait-ForOKHeartbeat {
    Param
    (
        [Parameter(Mandatory)]
        [VM]$VM,
        [Parameter(Mandatory)]
        [HyperVServer]$HyperVServer
    )

    while ((Get-VM -Name $VM.Name -ComputerName $HyperVServer.Name).HeartBeat -ne 'OkApplicationsUnknown') {
        Start-Sleep -Seconds 1
        $name = $VM.Name
        #Probs only want to do this when -verbose
        Write-Verbose "$name not ready. Waiting"

    }

}
function Wait-ForResponsiveVM {
    Param
    (
        [Parameter(Mandatory)]
        [VM]$VM,
        [Parameter(Mandatory)]
        [HyperVServer]$HyperVServer
    )

    Wait-ForOKHeartbeat -VM $VM -HyperVServer $HyperVServer

    #Wait for DHCP to assign IP
    while ($null -eq ((Get-VMNetworkAdapter -VMName $VM.Name -ComputerName $HyperVServer.Name).IpAddresses | Where-Object { $_ -notmatch ':' } | Select-Object -First 1)) {
        Start-Sleep -Seconds 1

        $name = $VM.Name
        Write-Verbose "$name has no IP yet. Waiting"

    }

    #Get VM IP Address
    $IP = (Get-VMNetworkAdapter -VMName $VM.Name -ComputerName $HyperVServer.Name).IpAddresses | Where-Object { $_ -notmatch ':' } | Select-Object -First 1

    write-Verbose "IP is $IP"
    Write-Verbose "Waiting for WinRM"

    #Wait for WINRM to be responsive
    $failedWSMan = $false
    $Future5 = (Get-Date).AddMinutes(5)

    do { 
        $failedWSMan = $false
        try {
            test-wsman $IP -ErrorAction Stop
        }
        catch { 
            $failedWSMan = $true
        }


    }while ($failedWSMan -and (Get-Date) -lt ($Future5))

    return $IP
}

function PostCreate-VM {
    Param
    (
        [Parameter(Mandatory)]
        [VM]$VM,
        [Parameter(Mandatory)]
        [HyperVServer]$HyperVServer

    )

    foreach ($script in $VM.PostCreate.Scripts) {
        Write-Verbose "Running Post Create Script $script"
        Invoke-Command -ComputerName $HyperVServer.Name -FilePath $script -ArgumentList $VM.Name
    }
}

function Initialize-VM {
    Param
    (
        [Parameter(Mandatory)]
        [VM]$VM,
        [Parameter(Mandatory)]
        [HyperVServer]$HyperVServer

    )

    Set-Item wsman:\localhost\Client\TrustedHosts -value * -Force

    $VMName = $VM.Name
   
    $ip = Wait-ForResponsiveVM -VM $VM -HyperVServer $HyperVServer
    if ($ip) {
        Write-Verbose "WinRM connection established"
    }
    else {
        throw "Timed out waiting for WinRM"
    }

    $newCred = $null

    $scriptCount = 0
    foreach ($script in $VM.Provisioning.Scripts) {

        $scriptCount++

        if ($script.EndsWith(".Set-Credential.ps1")) {
                
            Write-Verbose "Credential script detected, getting credentials"
    
            $credObject = invoke-expression -Command $script
    
            if ($credObject -and $credObject.GetType().Name -eq 'PSCredential') {
                Write-Verbose "New credentials set" 
    
                $newCred = $credObject
            }
        }
        elseif ($script.EndsWith(".Validate.ps1")) {

            
            $InvokeParams = @{ 
                FilePath     = $script
                ComputerName = $ip[1]
            }
               
            if ($newCred) {
                $InvokeParams.Add("Credential", $newCred)
            }
            try {
                invoke-command @InvokeParams -ErrorAction Stop      
            }
            catch {
                write-host "Validation script failed"
                if ($VM.Provisioning.RebuildOnValidationFailure -eq $true) {
                    throw "$VMName failed validation process - REBUILD NEEDED"

                }
                else {
                    throw "$VMName failed validation process"
                }

            }
        }
        else {
    
            try {
                Write-Verbose "Provisioning $VMName using $script" 
    
                $InvokeParams = @{ 
                    FilePath     = $script
                    ComputerName = $ip[1]
                }
               
                if ($newCred) {
                    $InvokeParams.Add("Credential", $newCred)
                }
                
                invoke-command @InvokeParams

                $lastScript = $scriptCount -eq $VM.Provisioning.Scripts.Count
        
                if ($VM.Provisioning.RebootAfterEachScript ) {

                    Write-Verbose "Rebooting $VMName"
                    
                    if (($VM.Provisioning.RebootAfterLastScript -eq $true) -or ($VM.Provisioning.RebootAfterLastScript -eq $false -and $lastScript -eq $false)) {
                        Stop-VM -Name  $VMName -ComputerName $HyperVServer.Name -Force -ErrorAction Stop
                        Start-VM -Name  $VMName -ComputerName $HyperVServer.Name -ErrorAction Stop
                
                        if ($lastScript -eq $false) {
                            Wait-ForResponsiveVM -VM $VM -HyperVServer $HyperVServer
                        }
                        else {
                            Write-Host "$script is last script, not waiting for VM to be responsive"
                        }
                    }

                
                }
            }
            catch {
                $_
                write-host "Provision failed"
                if ($VM.Provisioning.$RebuildOnProvisionFailure -eq $true) {
                    throw "$VMName failed provision process - REBUILD NEEDED"

                }
                else {
                    throw "$VMName failed provision process"
                }
            }
            
        }

    }
        

}




