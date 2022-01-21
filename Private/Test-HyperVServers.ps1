function Test-HyperVServers {
    Param
    (
        [Parameter(Mandatory)]
        [HyperVServer[]]$HyperVServers
    )

    foreach ($server in $HyperVServers) {
        if (!([bool](Test-WSMan -ComputerName $server.Name))) {
           
            throw "Unable to connect to $server using WinRM, check that WinRM is enabled and $server is reachable and try again" 
                
        }

        if ($server.SwitchName){
            try{
                Get-VMSwitch -ComputerName $server.Name -Name $server.SwitchName -ErrorAction Stop
            }catch{
                throw "Unable to find switch $($server.SwitchName) on $($server.Name), check that the switch exists and try again"
            }
        }
    }

    Write-Host "Connectivity Test Passed" -ForegroundColor Green
    
}