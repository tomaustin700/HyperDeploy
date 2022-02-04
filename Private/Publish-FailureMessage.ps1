function Publish-FailureMessage {
    Param
    (
        [Parameter(Mandatory)]
        [string]$VMName

    )

    Write-Host "Failed to create VM: $VMName" -ForegroundColor Red

}