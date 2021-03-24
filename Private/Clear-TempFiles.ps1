function Clear-TempFiles {
    Param
    (
        [string[]]$HyperVServers
    )

    foreach ($server in $HyperVServers) {
        Invoke-Command -ComputerName $server {

            $temp = $env:TEMP
            $tempGI = "$temp\HyperDeployGoldenImage.vhdx"

            Write-Verbose "Removing $tempGI"

            if (Test-Path $tempGI) {
                Remove-Item $tempGI -Force
            }

        }
    }
    
}

