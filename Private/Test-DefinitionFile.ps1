function Test-DefinitionFile {
    Param
    (
        [Parameter(Mandatory)]
        [string]$HyperVServers
    )

    Write-Host "Parsing defintion..." -ForegroundColor Yellow
    try {
        $definition = [Definition](Get-Content $DefinitionFile -Raw | Out-String | ConvertFrom-Json)
        Write-Host "Definition Valid" -ForegroundColor Green
    }
    catch {
        Write-Host "Unable to parse definition file" -ForegroundColor Red
        if ($Verbose) {
            Write-Host $_.Exception
        }
    }

    return $definition
}