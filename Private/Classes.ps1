class HyperVServer {
    [string]$Name
    [int]$MaxVMCount
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

class Definition {
    [HyperVServer[]]$HyperVServers
    [VM[]]$VMs
}