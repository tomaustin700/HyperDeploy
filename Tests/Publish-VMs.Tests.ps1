Describe 'Publish-VMs Tests' {

    It 'AddingMoreReplicasThanMaxReplicas_ShouldThrow' {

        $rootDir = (get-item $PSScriptRoot).Parent.FullName
        . "$rootDir\Private\Publish-VMs.ps1"
        . "$rootDir\Private\Classes.ps1"
   

        $vms = @()
        $vms += [VM]@{Name = "Test1"; Replicas = 10; HyperVServers = @([HyperVServer]@{ MaxReplicas = 5 }) }

        { Publish-VMs  -VMs $vms } | Should -Throw "Not enough Hypervisor capacity for VM's"
    
    }

    It 'HavingEnoughHypervisorCapacityForVMs_ShouldNotThrow' {

        $rootDir = (get-item $PSScriptRoot).Parent.FullName
        . "$rootDir\Private\Publish-VMs.ps1"
        . "$rootDir\Private\Classes.ps1"

        Mock Confirm-ExistingVMRemovalAndAdd
    
        $vms = @()
        $vms += [VM]@{Name = "Test1"; Replicas = 10; HyperVServers = @([HyperVServer]@{ MaxReplicas = 20 }) }

        { Publish-VMs  -VMs $vms } | Should -Not -Throw "Not enough Hypervisor capacity for VM's"    
    }


}