function Clear-TempFiles {
    Param
    (
        [HyperVServer[]]$HyperVServers
    )

    foreach ($server in $HyperVServers) {
        Invoke-Command -ComputerName $server.Name {

            $temp = $env:TEMP
            $tempGI = "$temp\HyperDeployGoldenImage.vhdx"

            if (Test-Path $tempGI) {
                Remove-Item $tempGI -Force
            }

        }
    }
    
    $temp = $env:TEMP
    $tempGI = "$temp\HyperDeployGoldenImage.vhdx"

    if (Test-Path $tempGI) {
        Remove-Item $tempGI -Force
    }
        

}

