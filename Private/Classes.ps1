class HyperVServer {
    [string]$Name
    [int]$MaxVMCount
}

class VM {
    [string]$Name
    [int]$Replicas
    [int]$ProcessorCount
    [string]$MemoryStartupMB
    [string]$MemoryMaximumMB
    [string]$GoldenImagePath
    [string]$VMHardDiskPath
    [string]$CheckpointType
}

class Definition {
    [HyperVServer[]]$HyperVServers
    [VM[]]$VMs
}