class HyperVServer {
    [string]$Name
    [System.Nullable[int]]$MaxReplicas
    [string]$SwitchName
    [string]$GoldenImagePath
    [string]$GoldenImageExtension
    [string]$VMHardDiskPath
}

class Provisioning {
    [bool]$RebootAfterEachScript
    [bool]$RebootAfterLastScript = $true
    [bool]$RebuildOnValidationFailure
    [string[]]$Scripts
}

class PostCreate {
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
    [int]$ReplicaStartIndex
    [int]$ProcessorCount
    [string]$MemoryStartupBytes
    [string]$MemoryMaximumBytes
    [string]$UNCCredentialScript
    [string]$CheckpointType
    [string]$NewVMDiskSizeBytes
    [PostCreate]$PostCreate
    [Provisioning]$Provisioning
    [HyperVServer[]]$HyperVServers
    [guid]$ReplicaGuid
    [string[]]$SkipNames
}

class DeploymentOptions {
    [bool]$StartAfterCreation
    [bool]$Parallel
}

class Definition {
    [DeploymentOptions]$DeploymentOptions
    [VM[]]$VMs
}