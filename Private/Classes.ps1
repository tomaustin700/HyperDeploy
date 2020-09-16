class HyperVServer {
    [string]$Name
    [System.Nullable[int]]$MaxVMCount
}

class Provisioning {
    [bool]$RebootAfterEachScript
    [string[]]$Scripts
}

class VM:System.ICloneable {

    [Object] Clone () {
        $NewVM = [VM]::New()
        foreach ($Property in ($this | Get-Member -MemberType Property)) {
            $NewVM.$($Property.Name) = $this.$($Property.Name)
        }
        return $NewVM
    }

    [string]$Name
    [int]$Replicas
    [int]$ProcessorCount
    [string]$MemoryStartupBytes
    [string]$MemoryMaximumBytes
    [string]$GoldenImagePath
    [string]$VMHardDiskPath
    [string]$CheckpointType
    [string]$SwitchName
    [string]$NewVMDiskSizeBytes
    [Provisioning]$Provisioning
}

class DeploymentOptions {
    [bool]$StartAfterCreation
}

class Definition {
    [DeploymentOptions]$DeploymentOptions
    [HyperVServer[]]$HyperVServers
    [VM[]]$VMs
}