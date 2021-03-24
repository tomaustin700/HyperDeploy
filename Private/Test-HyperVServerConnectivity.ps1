function Test-HyperVServerConnectivity {
    Param
    (
        [Parameter(Mandatory)]
        [string[]]$HyperVServers
    )

    foreach ($server in $HyperVServers) {
        if (!([bool](Test-WSMan -ComputerName $server))) {
           
            throw "Unable to connect to $server using WinRM, check that WinRM is enabled and $server is reachable and try again" 
                
        }
    }

    Write-Host "Connectivity Test Passed" -ForegroundColor Green
    
}