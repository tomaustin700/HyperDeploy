function Publish-VMs {
    Param
    (
        [Parameter(Mandatory)]
        [VM[]]$VMs,
        [HyperVServer[]]$HyperVServers
    )

    [System.Collections.ArrayList]$VMList = $VMs
    if ($VMs.Where( { $_.Replicas -gt 0 }, 'First').Count -gt 0) {
        #Replicas Detected
        foreach ($replicasRequired in $VMs.Where{ $_.Replicas -gt 0 }) {
            $VMList.Remove($replicasRequired)

            For ($i = 1; $i -le $replicasRequired.Replicas; $i++) {
                $replica = $replicasRequired.Clone()
                $replica.Name = $replica.Name + $i
                $replica.Replicas = 0
                $VMList.Add($replica) > $null
            }
        }
    }

    if ($HyperVServers.Count -gt 0) {

        $HyperVAmount = $HyperVServers.Count
        $HyperVLists = @{}
        $Count = 0
        $FilledVMs = @()

        do {

            $VMList.ToArray() | ForEach-Object {
                $Server = $HyperVServers[$Count % $HyperVAmount]
                if (($HyperVLists[$Server].Count + 1) -le $Server.MaxVMCount) {
                    $HyperVLists[$Server] += @($_)
                    $VMList.Remove($_)
                }
                $Count++
            }

            foreach ($server in $HyperVServers | Where-Object { $FilledVMs -notcontains $_.Name }) {

                $sName = $server.Name
                $n = $HyperVLists.Keys | Where-Object { $_.Name -eq $sName } | Select-Object 
                $c = $HyperVLists[$n]
                $l = $c.Length
                $mvmc = $server.MaxVMCount

                if ($mvmc -eq $l) {
                    $FilledVMs += $sName
                }
            }

            if ($FilledVMs.Length -eq $HyperVServers.Length -and $VMList.Count -gt 0) {
                Write-Host "Not enough Hypervisor capacity for VM's" -ForegroundColor Red
                Exit 1
            }

        }while ($VMList.Count -gt 0) 

        foreach ($key in $HyperVLists.Keys) {
            foreach ($vm in $HyperVLists[$key]) {
                Submit-VM -VM $vm -HyperVServer $key
            }
        }
    }
    else {
        foreach ($vm in $VMList) {
            Submit-VM -VM $vm 
        }
    }
}
