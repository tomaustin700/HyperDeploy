class HyperVServer {
    [string]$Name
    [System.Nullable[int]]$MaxVMCount
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
}

class DeploymentOptions {
    [bool]$StartAfterCreation
}

class Definition {
    [DeploymentOptions]$DeploymentOptions
    [HyperVServer[]]$HyperVServers
    [VM[]]$VMs
}