function Confirm-ExistingVMRemovalAndAdd {

    Param
    (
        [Parameter(Mandatory)]
        [VM]$VM,
        [HyperVServer]$HyperVServer,
        [string[]]$HyperVServers,
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
        [string[]]$HyperVServers,
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
            $startReplicas = $replicasRequired.Replicas

            $replicaStartIndex = 1
            if ($replicasRequired.ReplicaStartIndex -gt 0) {
                $replicaStartIndex = $replicasRequired.ReplicaStartIndex;
                $replicasRequired.Replicas = $replicasRequired.Replicas + $replicaStartIndex - 1
            }

            foreach ($server in $replicasRequired.HyperVServers) {
                if ($server.MaxReplicas) {
                    $crossServerMaxReplicas += $server.MaxReplicas
                }
            }

            if ($startReplicas -gt $crossServerMaxReplicas) {
                throw "Not enough Hypervisor capacity for VM's" 
            }

            $hyperVIndex = 0;
            $guid = [guid]::NewGuid()
            
            For ($replicaStartIndex; $replicaStartIndex -le $replicasRequired.Replicas; $replicaStartIndex++) {
                $replica = $replicasRequired.Clone()
                $replica.Name = $replica.Name + $replicaStartIndex
                $replica.Replicas = 0
                $replica.ReplicaGuid = $guid
                $orginalServers = $replica.HyperVServers

                $allocatedServer = $replica.HyperVServers[$hyperVIndex]
                $replica.HyperVServers = @()
                if ($allocatedServer.MaxReplicas) {
                    #Do logic to calculate how many replicas already allocated to hypervisor, if assigning this one would breach then increment hypervindex
                    do {
                        $allocated = $false
                        $allocatedServer = $orginalServers[$hyperVIndex]

                        $reps = $VMList | Where-Object { $_.ReplicaGuid -eq $guid -and $_.HyperVServers[0].Name -eq $allocatedServer.Name }

                        if ($reps.Count -eq $allocatedServer.MaxReplicas) {
                            #Pick new server as allocated one at max

                            if ($hyperVIndex + 1 -eq $orginalServers.Length) {
                                $hyperVIndex = 0;
                            }
                            else {
                                $hyperVIndex++;
                            }
                        }
                        else {
                            $replica.HyperVServers += $allocatedServer
                            $allocated = $true
                        }
                    }
                    While (!$allocated)

                }
                else {
                    $replica.HyperVServers += $allocatedServer
                }

                if ($hyperVIndex + 1 -eq $orginalServers.Length) {
                    $hyperVIndex = 0;
                }
                else {
                    $hyperVIndex++;
                }
                
                $VMList.Add($replica) > $null
            }

            if ($replicasRequired.SkipNames.Length -gt 0) {
                Write-Verbose "Skips detected"
                foreach ($skip in $replicasRequired.SkipNames) {
                    $vms = $VMList
                    foreach ($vm in $vms) {
                        if ($vm.Name -eq $skip) {
                            $newVm = $vm
                            $VMList.Remove($vm) 

                            $last = $VMList[-1]

                            $iteration = ([int]($last.Name -replace '\D+(\d+)','$1')) +1 

                            $newVm.Name = "Automation$iteration"
                            $VMList.Add($newVm)
                        }
                    }
                }
            }
        }
    }

    write-output $VMList

    if (!$Destroy) {

        if ($DeploymentOptions.Parallel) {
            Get-Job | Remove-Job -Force
            $MaxThreads = 5
        }

        $addBlock = {

            Param(
                [object] $VM,
                [object] $Provisioning,
                [object] $HyperVServer,
                [object] $HyperVServers,
                [object] $DeploymentOptions,
                [object] $Replace
            )

            . .\Private\Publish-VMs.ps1
            . .\Private\Add-VM.ps1
            . .\Private\Assert-VMAlreadyExists.ps1
            . .\Private\Classes.ps1
            . .\Private\Initialize-VM.ps1
            . .\Private\Remove-VM.ps1

            $VM.Provisioning = $Provisioning

            Confirm-ExistingVMRemovalAndAdd -VM $VM -HyperVServers $HyperVServers -HyperVServer $vm.HyperVServers[0] -DeploymentOptions $DeploymentOptions -Replace $Replace -Force $true 
        }
        Write-Host "Adding Virtual Machines" -ForegroundColor Yellow


        foreach ($vm in $VMList) {
            if ($DeploymentOptions.Parallel) {
                While ($(Get-Job -state running).count -ge $MaxThreads) {
                    Start-Sleep -Milliseconds 3
                }
                Start-Job -Scriptblock $addBlock -ArgumentList $vm, $vm.Provisioning, $key, $HyperVServers, $DeploymentOptions, $Replace
            }
            else {
                Confirm-ExistingVMRemovalAndAdd -VM $vm -HyperVServers $HyperVServers -HyperVServer $vm.HyperVServers[0] -DeploymentOptions $DeploymentOptions -Replace $Replace -Force $Force 
            }
        }

        if ($DeploymentOptions.Parallel) {
            While ($(Get-Job -State Running).count -gt 0) {
                start-sleep 1
            }
    
            #Get information from each job.
            foreach ($job in Get-Job) {
                $info = Receive-Job -Id ($job.Id)
            }
                
            #Remove all jobs created.
            Get-Job | Remove-Job
        }

        Write-Host "Virtual Machines Added" -ForegroundColor Green

    }
    else {
        Write-Host "Starting Destroy" -ForegroundColor Red

        if ($DeploymentOptions.Parallel) {
            Get-Job | Remove-Job -Force
            $MaxThreads = 5
        }

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
            if ($existingVM) {
                Remove-VM  $vm.Name -ComputerName $existingHypervisor
            }
        }

        foreach ($vm in $VMList) {
            if ($DeploymentOptions.Parallel) {
                While ($(Get-Job -state running).count -ge $MaxThreads) {
                    Start-Sleep -Milliseconds 3
                }
                Start-Job -Scriptblock $destroyBlock -ArgumentList $vm, $HyperVServers, $Force
            }
            else {
                $existingVM, $existingHypervisor = Assert-VMAlreadyExists -VM $vm -HyperVServers $HyperVServers
                if ($existingVM -and !$Force) {
                    $name = $existingVM.Name
                    Write-Host "Remove $name ?" -ForegroundColor Red
                    $RemoveConfirm = Read-Host "Press Y to confirm" 
                    if ($RemoveConfirm.ToLower() -eq "y") {
                        Remove-VM  $vm.Name -ComputerName $existingHypervisor
                    }
                    else {
                        throw
                    }
                }
                elseif ($existingVM -and $Force) {
                    Remove-VM  $vm.Name -ComputerName $existingHypervisor
                }
            }
        }

        if ($DeploymentOptions.Parallel) {
            While ($(Get-Job -State Running).count -gt 0) {
                start-sleep 1
            }

            #Get information from each job.
            foreach ($job in Get-Job) {
                $info = Receive-Job -Id ($job.Id)
            }
        
            #Remove all jobs created.
            Get-Job | Remove-Job
        }

        Write-Host "Destroy Complete" -ForegroundColor Red

    }
    
   
}
