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
                $hyperVServer = $HyperVServers[0].Name
            }
            else {
                
                if (!$hyperVIndex) {
                    #First iteration so just use first Hyper-V Server
                    $hyperVServer = $HyperVServers[0].Name
                    $hyperVIndex = 0
                }
                else {
                    $reqIndex = $hyperVIndex + 1
                    if ($HyperVServers[$reqIndex]) {
                        $hyperVServer = $HyperVServers[$reqIndex].Name
                        $hyperVIndex = $reqIndex
                    }
                    else {
                        $hyperVServer = $HyperVServers[0].Name
                        $hyperVIndex = 0
                    }
                }

                #Check Server has capacity
                if ($HyperVServers[$hyperVIndex].MaxVMCount -gt 0){
                    
                }
                

            }
            Submit-VM -VM $vm -HyperVServer $hyperVServer
        }
    }
}