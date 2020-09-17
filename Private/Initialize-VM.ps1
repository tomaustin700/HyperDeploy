
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
        Write-Output "$name has no IP yet. Waiting"

    }

    #Get VM IP Address
    $IP = (Get-VMNetworkAdapter -VMName $VM.Name -ComputerName $HyperVServer.Name).IpAddresses[0] 

    #Wait for WINRM to be responsive
    $failedWSMan = $false

    do { 
        $failedWSMan = $false
        try {
            test-wsman $IP -ErrorAction Stop
        }
        catch { 
            $failedWSMan = $true
        }


    }while ($failedWSMan)

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
    $script = $VM.ProvisionScript
    Write-Host "Provisioning $name using $script" -ForegroundColor Yellow
    $ip = Wait-ForResponsiveVM -VM $VM -HyperVServer $HyperVServer

    foreach($script in $VM.Provisioning.Scripts){

        $script = Get-Content $script

        invoke-command  -ScriptBlock $script -ComputerName $ip -Credential $ProvisionCredential

        if ($VM.Provisioning.RebootAfterEachScript){
            Stop-VM -Name $name -ComputerName $HyperVServer.Name -Force
            Start-VM -Name $name -ComputerName $HyperVServer.Name
    
            WaitForResponsive-VM $VM -HyperVServer $HyperVServe
        }

    }


}