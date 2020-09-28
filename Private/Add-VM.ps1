function Add-VM {
    Param
    (
        [Parameter(Mandatory)]
        [VM]$VM,
        [Parameter(Mandatory)]
        [HyperVServer]$HyperVServer,
        [DeploymentOptions]$DeploymentOptions

    )
    
    $NewVMParams = @{ 
        Name               = $VM.Name
        MemoryStartupBytes = [int64][scriptblock]::Create($VM.MemoryStartupBytes).Invoke()[0] 
        ComputerName       = $HyperVServer.Name
    }

    if ($VM.SwitchName) {
        $NewVMParams.Add("SwitchName", $VM.SwitchName)
    }

    $SetVMParams = @{ 
        Name               = $VM.Name
        ProcessorCount     = $VM.ProcessorCount
        MemoryMaximumBytes = [int64][scriptblock]::Create($VM.MemoryMaximumBytes).Invoke()[0]  
        ComputerName       = $HyperVServer.Name
    }

    if ($VM.CheckpointType) {
        $SetVMParams.Add("CheckpointType", $VM.CheckpointType)
    }

    New-VM  @NewVMParams | out-null
    Set-VM @SetVMParams

    if ($VM.VMHardDiskPath) {

        $diskPath = $VM.VMHardDiskPath + "\" + $VM.Name

        Invoke-Command -ComputerName $HyperVServer.Name { 
            if (!(Test-Path -Path $using:diskPath)) {
                New-Item -ItemType directory -Path $using:diskPath -Force
            }
        } 
        
        if ($VM.GoldenImagePath) {
            Write-Verbose "Copying golden image"

            $path = $VM.GoldenImagePath

            if ($VM.GoldenImagePath.StartsWith("\\")) {

                $uncCreds = invoke-expression -Command $VM.UNCCredentialScript

                if ($uncCreds -and $uncCreds.GetType().Name -eq 'PSCredential') {

                    Invoke-Command -ComputerName $HyperVServer.Name -ScriptBlock { Register-PSSessionConfiguration -Name HyperDeploy -RunAsCredential $using:uncCreds -Force }

                    Invoke-Command  -ConfigurationName HyperDeploy -ComputerName $HyperVServer.Name { 
                        $localPath = $using:path
    
                        $temp = $env:TEMP
                        $tempGI = "$temp\HyperDeployGoldenImage.vhdx"
        
                        if (!(Test-Path "filesystem::$localPath")) {
                            throw "$localPath does not exist"
                            
                        }
        
                        if (!(Test-Path $tempGI)) {
                            Write-Verbose "Golden Image Path is UNC, caching locally."
                            Copy-Item "filesystem::$localPath" -Destination $tempGI
                        }
                        
                        Copy-Item $tempGI -Destination "$using:diskPath\Disk.vhdx"
                    
                    }
                }else{
                    throw "UNCCredentialScript did not return a valid PSCredential object"
                }
            }
            else {
                Invoke-Command   -ComputerName $HyperVServer.Name { 
                    if (!(Test-Path $localPath)) {
                        throw "$localPath does not exist"
                    }

                    Copy-Item $localPath -Destination "$using:diskPath\Disk.vhdx"
                }
            }
        }
        elseif ($VM.NewVMDiskSizeBytes) {

            $NewVHDParams = @{ 
                Path         = "$diskPath\Disk.vhdx"
                SizeBytes    = [int64][scriptblock]::Create($VM.NewVMDiskSizeBytes).Invoke()[0]
                ComputerName = $HyperVServer.Name
            }
            New-VHD @NewVHDParams
        }

        $AddVMHardDiskDriveParams = @{ 
            Path         = "$diskPath\Disk.vhdx"
            VMName       = $VM.Name
            ComputerName = $HyperVServer.Name
        }

        Add-VMHardDiskDrive @AddVMHardDiskDriveParams
    }

    if ($DeploymentOptions -and $DeploymentOptions.StartAfterCreation) {

        Write-Verbose "Starting VM"

        $StartVMParams = @{ 
            Name         = $VM.Name
            ComputerName = $HyperVServer.Name
        }

        Start-VM @StartVMParams

        if ($VM.Provisioning) {

            $InitializeVMParams = @{ 
                VM           = $VM
                HyperVServer = $HyperVServer
            }

            Initialize-VM @InitializeVMParams  
        }
    }

}