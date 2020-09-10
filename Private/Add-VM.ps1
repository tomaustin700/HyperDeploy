function Add-VM {
    Param
    (
        [Parameter(Mandatory)]
        [VM]$VM,
        [HyperVServer]$HyperVServer
    )
    
    Write-Host $HyperVServer.Name
    Write-Host $VM.Name

    # New-vm -Name $VM.Name -MemoryStartupBytes 1GB -SwitchName $VM.SwitchName
    # Set-vm -Name $vm -ProcessorCount 2 -MemoryMaximumBytes 4GB -CheckpointType Disabled

}