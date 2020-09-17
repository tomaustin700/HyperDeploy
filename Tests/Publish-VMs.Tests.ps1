Describe 'Publish-VMs Tests' {

    It 'AddingMoreVMsThanHypervisorCapacity_ShouldThrow' {

        $rootDir = (get-item $PSScriptRoot).Parent.FullName
        . "$rootDir\Private\Publish-VMs"
        . "$rootDir\Private\Classes"
    
        $servers = @()
        $servers += [HyperVServer]@{Name = $env:computername; MaxVMCount = 1 }

        $vms = @()
        $vms += [VM]@{Name = "Test1" }
        $vms += [VM]@{Name = "Test2" }

        { Publish-VMs -HyperVServers $servers -VMs $vms } | Should -Throw "Not enough Hypervisor capacity for VM's"
    
    }

    It 'HavingEnoughHypervisorCapacityForVMs_ShouldNotThrow' {

        $rootDir = (get-item $PSScriptRoot).Parent.FullName
        . "$rootDir\Private\Publish-VMs"
        . "$rootDir\Private\Classes"

        Mock Confirm-ExistingVMRemovalAndAdd
    
        $servers = @()
        $servers += [HyperVServer]@{Name = $env:computername; MaxVMCount = 3 }

        $vms = @()
        $vms += [VM]@{Name = "Test1" }
        $vms += [VM]@{Name = "Test2" }

        { Publish-VMs -HyperVServers $servers -VMs $vms } | Should -Not -Throw "Not enough Hypervisor capacity for VM's"
    
    }

    # It 'VMsAreLoadBalancedOverHypervisors_MockCalled' {

    #     $rootDir = (get-item $PSScriptRoot).Parent.FullName
    #     . "$rootDir\Private\Publish-VMs"
    #     . "$rootDir\Private\Classes"
    #     . "$rootDir\Private\Assert-VMAlreadyExists"
    #     . "$rootDir\Private\Add-VM"

    #     Mock Assert-VMAlreadyExists { return ($null, $null)}
    #     Mock Add-VM
    
    #     $servers = @()
    #     $servers += [HyperVServer]@{Name = "Hyper1"; MaxVMCount = 1 }
    #     $servers += [HyperVServer]@{Name = "Hyper2"; MaxVMCount = 1 }

    #     $vms = @()
    #     $vms += [VM]@{Name = "Test1" }
    #     $vms += [VM]@{Name = "Test2" }

    #     write-host Publish-VMs -HyperVServers $servers -VMs $vms
        
    
    # }

}