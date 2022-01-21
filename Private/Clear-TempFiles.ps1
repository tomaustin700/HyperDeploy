function Clear-TempFiles {
    Param
    (
        [string[]]$HyperVServers
    )

    foreach ($server in $HyperVServers) {

        if ($server -eq $env:COMPUTERNAME) {
            $temp = $env:TEMP
            Write-Verbose "Removing Temp Golden Image if exists"

            if (Test-Path -Path "$temp\HyperDeployGoldenImage.vhdx") {
                Remove-Item "$temp\HyperDeployGoldenImage.vhdx" -Force

            }
            elseif (Test-Path -Path "$temp\HyperDeployGoldenImage.vhd") {
                Remove-Item "$temp\HyperDeployGoldenImage.vhd" -Force
            }
        }
        else {
            Invoke-Command -ComputerName $server {

                $temp = $env:TEMP
                Write-Verbose "Removing Temp Golden Image if exists"
    
                if (Test-Path -Path "$temp\HyperDeployGoldenImage.vhdx") {
                    Remove-Item "$temp\HyperDeployGoldenImage.vhdx" -Force
    
                }
                elseif (Test-Path -Path "$temp\HyperDeployGoldenImage.vhd") {
                    Remove-Item "$temp\HyperDeployGoldenImage.vhd" -Force
                }
    
            } 
        }

       
    }
    
}

