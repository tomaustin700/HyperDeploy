function Confirm-ExistingVMRemovalAndAdd {

    Param
    (
        [Parameter(Mandatory)]
        [VM]$VM,
        [HyperVServer]$HyperVServer,
        [HyperVServer[]]$HyperVServers,
        [bool] $Replace,
        [bool] $Force,
        [DeploymentOptions] $DeploymentOptions

    )

    $existingVM, $existingHypervisor = Assert-VMAlreadyExists -VM $VM -HyperVServers $HyperVServers
    if ($existingVM -and $Replace -and !$Force) {
        $name = $existingVM.Name
        Write-Host "$name already exists, replace?" -ForegroundColor Red
        $ReplaceConfirm = Read-Host "Press Y to confirm" 
        if ($ReplaceConfirm.ToLower() -eq "y") {
            Remove-VM  $VM.Name -ComputerName $existingHypervisor
            Add-VM -VM $VM -HyperVServer $HyperVServer -DeploymentOptions $DeploymentOptions 
        }
        else {
            throw
        }
    }
    elseif ($existingVM -and $Replace -and $Force) {
        Write-Verbose "Existing VM found, replacing."
        Remove-VM $VM.Name -ComputerName $existingHypervisor
        Add-VM -VM $VM -HyperVServer $HyperVServer -DeploymentOptions $DeploymentOptions 
    }
    elseif (!$existingVM) {
        Add-VM -VM $VM -HyperVServer $HyperVServer -DeploymentOptions $DeploymentOptions 
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
        [bool] $Force,
        [bool] $Destroy

    )

    [System.Collections.ArrayList]$VMList = $VMs
    if ($VMs.Where( { $_.Replicas -gt 0 }, 'First').Count -gt 0) {
        #Replicas Detected
        foreach ($replicasRequired in $VMs.Where{ $_.Replicas -gt 0 }) {
            $VMList.Remove($replicasRequired)

            $replicaStartIndex = 1
            if ($replicasRequired.ReplicaStartIndex -gt 0) {
                $replicaStartIndex = $replicasRequired.ReplicaStartIndex;
            }
            
            For ($replicaStartIndex; $replicaStartIndex -le $replicasRequired.Replicas; $replicaStartIndex++) {
                $replica = $replicasRequired.Clone()
                $replica.Name = $replica.Name + $replicaStartIndex
                $replica.Replicas = 0
                $VMList.Add($replica) > $null
            }
        }
    }

    $HyperVAmount = $HyperVServers.Count
    $HyperVLists = @{}
    $Count = 0
    $FilledVMs = @()

    if (!$Destroy) {

        do {

            foreach ($server in $HyperVServers) {
                $currentCount = (Get-VM -ComputerName $server.Name | Where-Object { ($VMList | Select-Object -Property Name -ExpandProperty Name) -notcontains $_.Name } ).count
                $server.MaxVMCount = $server.MaxVMCount - $currentCount
                $serverCapacity += $server.MaxVMCount
            }

            $VMList.ToArray() | ForEach-Object {
                $Server = $HyperVServers[$Count % $HyperVAmount]
                if (($HyperVLists[$Server].Count + 1) -le $Server.MaxVMCount) {
                    $HyperVLists[$Server] += @($_)
                    $VMList.Remove($_)
                }
                $Count++
            }

            foreach ($server in $HyperVServers | Where-Object { $FilledVMs -notcontains $_.Name } | Where-Object { $_.MaxVMCount -gt 0 } ) {

                $sName = $server.Name
                $n = $HyperVLists.Keys | Where-Object { $_.Name -eq $sName } | Select-Object 
                $c = $HyperVLists[$n]
                $l = $c.Length
                $mvmc = $server.MaxVMCount

                if ($mvmc -eq $l) {
                    $FilledVMs += $sName
                }
            }

            if ($serverCapacity -le 0 -or ($FilledVMs.Length -eq $HyperVServers.Length -and $VMList.Count -gt 0)) {
                throw "Not enough Hypervisor capacity for VM's" 
            }

        }while ($VMList.Count -gt 0) 


        Get-Job | Remove-Job -Force
        $MaxThreads = 5

        $addBlock = {

            Param(
                [object] $VM,
                [object] $Provisioning,
                [object] $HyperVServer,
                [object] $HyperVServers,
                [object] $DeploymentOptions,
                [object] $Replace,
                [object] $Force
            )

            . .\Private\Publish-VMs.ps1
            . .\Private\Add-VM.ps1
            . .\Private\Assert-VMAlreadyExists.ps1
            . .\Private\Classes.ps1
            . .\Private\Initialize-VM.ps1
            . .\Private\Remove-VM.ps1

            $VM.Provisioning = $Provisioning

            Confirm-ExistingVMRemovalAndAdd -VM $VM -HyperVServers $HyperVServers -HyperVServer $HyperVServer -DeploymentOptions $DeploymentOptions -Replace $Replace -Force $Force 
        }

        foreach ($key in $HyperVLists.Keys) {
       
            Write-Host "Adding Virtual Machines" -ForegroundColor Yellow

            foreach ($vm in $HyperVLists[$key]) {

                While ($(Get-Job -state running).count -ge $MaxThreads) {
                    Start-Sleep -Milliseconds 3
                }
                Start-Job -Scriptblock $addBlock -ArgumentList $vm, $vm.Provisioning, $key, $HyperVServers, $DeploymentOptions, $Replace, $Force
            }

            While ($(Get-Job -State Running).count -gt 0) {
                start-sleep 1
            }

            #Get information from each job.
            foreach ($job in Get-Job) {
                $info = Receive-Job -Id ($job.Id)
            }
            
            #Remove all jobs created.
            Get-Job | Remove-Job

            Write-Host "Virtual Machines Added" -ForegroundColor Green

        }
    }
    else {
        Write-Host "Starting Destroy" -ForegroundColor Red

        Get-Job | Remove-Job -Force
        $MaxThreads = 20

        $destroyBlock = {

            Param(
                [object] $vm,
                [object] $HyperVServers,
                [object] $Force
            )

            . .\Private\Publish-VMs.ps1
            . .\Private\Add-VM.ps1
            . .\Private\Assert-VMAlreadyExists.ps1
            . .\Private\Classes.ps1
            . .\Private\Initialize-VM.ps1
            . .\Private\Remove-VM.ps1

            $existingVM, $existingHypervisor = Assert-VMAlreadyExists -VM $vm -HyperVServers $HyperVServers
            if ($existingVM -and !$Force) {
                $name = $existingVM.Name
                Write-Host "Remove $name ?" -ForegroundColor Red
                $RemoveConfirm = Read-Host "Press Y to confirm" 
                if ($RemoveConfirm.ToLower() -eq "y") {
                    Remove-VM  $VM.Name -ComputerName $existingHypervisor
                }
                else {
                    throw
                }
            }
            elseif ($existingVM -and $Force) {
                Remove-VM  $VM.Name -ComputerName $existingHypervisor
            }
        }

        foreach ($vm in $VMList) {

            While ($(Get-Job -state running).count -ge $MaxThreads) {
                Start-Sleep -Milliseconds 3
            }
            Start-Job -Scriptblock $destroyBlock -ArgumentList $vm, $HyperVServers, $Force
        }

        While ($(Get-Job -State Running).count -gt 0) {
            start-sleep 1
        }

        #Get information from each job.
        foreach ($job in Get-Job) {
            $info = Receive-Job -Id ($job.Id)
        }
        
        #Remove all jobs created.
        Get-Job | Remove-Job

        Write-Host "Destroy Complete" -ForegroundColor Red

    }
    
   
}
