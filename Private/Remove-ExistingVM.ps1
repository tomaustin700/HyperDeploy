function Remove-ExistingVM {
    Param
    (
        [Parameter(Mandatory)]
        [VM]$VM,
        [string]$HyperVServer
    )

    $name = $VM.Name
    Write-Host "Removing $name from $HyperVServer" -ForegroundColor Red

    

}