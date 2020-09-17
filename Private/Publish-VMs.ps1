function Confirm-ExistingVMRemovalAndAdd {

    Param
    (
        [Parameter(Mandatory)]
        [VM]$VM,
        [HyperVServer[]]$HyperVServers,
        [bool] $Replace,
        [bool] $Force,
        [DeploymentOptions] $DeploymentOptions,
        [PSCredential]$ProvisionCredential

    )

    $existingVM, $existingHypervisor = Assert-VMAlreadyExists -VM $VM -HyperVServers $HyperVServers
    if ($existingVM -and $Replace -and !$Force) {
        $name = $existingVM.Name
        Write-Host "$name already exists, replace?" -ForegroundColor Red
        $ReplaceConfirm = Read-Host "Press Y to confirm" 
        if ($ReplaceConfirm.ToLower() -eq "y") {
            Remove-VM  $VM.Name -ComputerName $existingHypervisor
            Add-VM -VM $VM -HyperVServer $key -DeploymentOptions $DeploymentOptions -ProvisionCredential $ProvisionCredential
        }
    }
    elseif ($existingVM -and $Replace -and $Force) {
        Remove-VM  $VM.Name -ComputerName $existingHypervisor
        Add-VM -VM $VM -HyperVServer $key -DeploymentOptions $DeploymentOptions -ProvisionCredential $ProvisionCredential
    }
    elseif (!$existingVM) {
        Add-VM -VM $VM -HyperVServer $key -DeploymentOptions $DeploymentOptions -ProvisionCredential $ProvisionCredential
    }

}

function Publish-VMs {
    Param
    (
        [Parameter(Mandatory)]
        [VM[]]$VMs,
        [HyperVServer[]]$HyperVServers,
        [DeploymentOptions]$DeploymentOptions,
        [bool] $Replace,
        [bool] $Clean,
        [bool] $Force,
        [PSCredential]$ProvisionCredential

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

    $HyperVAmount = $HyperVServers.Count
    $HyperVLists = @{}
    $Count = 0
    $FilledVMs = @()

    do {

        #Need some logic here to subtract already existing vms from max count

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
            throw "Not enough Hypervisor capacity for VM's" 
        }

    }while ($VMList.Count -gt 0) 

    

    foreach ($key in $HyperVLists.Keys) {
       
        Write-Host "Adding Virtual Machines" -ForegroundColor Yellow
        foreach ($vm in $HyperVLists[$key]) {
            Confirm-ExistingVMRemovalAndAdd -VM $vm -HyperVServers $HyperVServers -DeploymentOptions $DeploymentOptions -Replace $Replace -Force $Force -ProvisionCredential $ProvisionCredential
        }
        Write-Host "Virtual Machines Added" -ForegroundColor Green

    }
    
   
}
