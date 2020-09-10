class HyperVServer {
    [string]$Name
    [int]$MaxVMCount
}

class VM:System.ICloneable {

    [Object] Clone () {
        $NewVM = [VM]::New()
        foreach ($Property in ($this | Get-Member -MemberType Property)) {
            $NewVM.$($Property.Name) = $this.$($Property.Name)
        } # foreach
        return $NewVM
    }

    [string]$Name
    [int]$Replicas
    [int]$ProcessorCount
    [string]$MemoryStartupMB
    [string]$MemoryMaximumMB
    [string]$GoldenImagePath
    [string]$VMHardDiskPath
    [string]$CheckpointType
    [String]$SwitchName
}

class Definition {
    [HyperVServer[]]$HyperVServers
    [VM[]]$VMs
}