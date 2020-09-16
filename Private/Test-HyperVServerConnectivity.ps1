function Test-HyperVServerConnectivity {
    Param
    (
        [Parameter(Mandatory)]
        [HyperVServer[]]$HyperVServers
    )

    if ($definition.HyperVServers.Count -gt 0) {
        Write-Host "Testing Connectivity" -ForegroundColor Yellow

        foreach ($server in $definition.HyperVServers) {
            if (!([bool](Test-WSMan -ComputerName $server.Name))) {
                $name = $server.Name
                throw "Unable to connect to $name using WinRM, check that WinRM is enabled and $name is reachable and try again" 
                
            }
        }

        Write-Host "Connectivity Test Passed" -ForegroundColor Green
    }
}