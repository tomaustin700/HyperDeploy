
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
        Write-Host "$name not ready. Waiting"

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
    while ((Get-VMNetworkAdapter -VMName $VM.Name -ComputerName $HyperVServer.Name).IpAddresses.Count -eq 0) {
        Start-Sleep -Seconds 1

        $name = $VM.Name
        Write-Host "$name has no IP yet. Waiting"

    }

    #Get VM IP Address
    $IP = (Get-VMNetworkAdapter -VMName $VM.Name -ComputerName $HyperVServer.Name).IpAddresses[0] 

    write-Host "IP is $IP"
    Write-Host "Waiting for WinRM"

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

function Initialize-VM {
    Param
    (
        [Parameter(Mandatory)]
        [VM]$VM,
        [Parameter(Mandatory)]
        [HyperVServer]$HyperVServer,
        [PSCredential]$ProvisionCredential

    )

    Set-Item wsman:\localhost\Client\TrustedHosts -value * -Force

    $name = $VM.Name
   
    $ip = Wait-ForResponsiveVM -VM $VM -HyperVServer $HyperVServer
    if ($ip) {
        Write-Host "WinRM connection established"
    }
    else {
        break "Timed out waiting for WinRM"
    }

    foreach ($script in $VM.Provisioning.Scripts) {

        Write-Host "Provisioning $name using $script" -ForegroundColor Yellow
        
        invoke-command -ComputerName $ip[1] -FilePath $script -Credential $ProvisionCredential

        if ($VM.Provisioning.RebootAfterEachScript) {
            Stop-VM -Name $name -ComputerName $HyperVServer.Name -Force
            Start-VM -Name $name -ComputerName $HyperVServer.Name
    
            Wait-ForResponsiveVM -VM $VM -HyperVServer $HyperVServer
        }

    }


}