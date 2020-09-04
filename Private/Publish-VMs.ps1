function Publish-VMs {
    Param
    (
        [Parameter(Mandatory)]
        [VM[]]$VMs,
        [HyperVServer[]]$HyperVServers
    )

    $hyperVIndex = $null

    foreach ($vm in $VMs) {
        
        if ($HyperVServers.Count -eq 0) {
            #Local deploy
            Submit-VM -VM $vm
        }
        else {
            #Win RM Deploy

            
            if ($HyperVServers.Count -eq 1) {
                $hyperVIndex = 0
            }
            else {

                if (!$hyperVIndex) {
                    #First iteration so just use first Hyper-V Server
                    $hyperVIndex = 0
                    
                }
                else {
                    $reqIndex = $hyperVIndex + 1
                    if ($HyperVServers[$reqIndex]) {
                        $hyperVIndex = $reqIndex
                    }
                    else {
                        $hyperVIndex = 0
                    }
                }

            }

            #Check Server has capacity
            if ($HyperVServers[$hyperVIndex].MaxVMCount -gt 0) {
                if ((Get-VM -ComputerName $HyperVServers[$hyperVIndex].Name | Measure-Object).Count -ge $HyperVServers[$hyperVIndex].MaxVMCount) {
                    
                }
            }

            Submit-VM -VM $vm -HyperVServer $hyperVServer
        }
    }
}