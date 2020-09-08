function Submit-VM {
    Param
    (
        [Parameter(Mandatory)]
        [VM]$VM,
        [HyperVServer]$HyperVServer
    )
    
    Write-Host $HyperVServer.Name
    Write-Host $VM.Name


}