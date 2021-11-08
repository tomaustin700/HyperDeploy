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

    if ($HyperVServer.SwitchName) {
        $NewVMParams.Add("SwitchName", $HyperVServer.SwitchName)
    }

    $SetVMParams = @{ 
        Name               = $VM.Name
        ProcessorCount     = $VM.ProcessorCount
        MemoryMaximumBytes = [int64][scriptblock]::Create($VM.MemoryMaximumBytes).Invoke()[0]  
        ComputerName       = $HyperVServer.Name
        DynamicMemory      = $true
    }

    if ($VM.CheckpointType) {
        $SetVMParams.Add("CheckpointType", $VM.CheckpointType)
    }

    New-VM  @NewVMParams | out-null
    Set-VM @SetVMParams

    if ($HyperVServer.VMHardDiskPath) {

        $diskPath = $HyperVServer.VMHardDiskPath + "\" + $VM.Name

        Invoke-Command -ComputerName $HyperVServer.Name { 
            if (!(Test-Path -Path $using:diskPath)) {
                New-Item -ItemType directory -Path $using:diskPath -Force
            }
        } 
        
        if ($HyperVServer.GoldenImagePath) {
            Write-Verbose "Copying golden image"

            $path = $HyperVServer.GoldenImagePath

            if ($HyperVServer.GoldenImagePath.StartsWith("\\")) {


                $uncCreds = invoke-expression -Command $VM.UNCCredentialScript

                if ($uncCreds -and $uncCreds.GetType().Name -eq 'PSCredential') {

                    Write-Verbose "Golden Image UNC Path detected - setting up credentials"

                    Invoke-Command -ComputerName $HyperVServer.Name -ScriptBlock { Register-PSSessionConfiguration -Name HyperDeploy -RunAsCredential $using:uncCreds -Force }

                    Write-Verbose "Waiting for WinRM service to be ready"

                    Start-Sleep -Seconds 30

                    Write-Verbose "Copying Golden Image"

                    Invoke-Command  -ConfigurationName HyperDeploy -ComputerName $HyperVServer.Name { 
                        $localPath = $using:path
    
                        $temp = $env:TEMP
                        $extension = $localPath.Split('.')[-1]

                        $tempGI = "$temp\HyperDeployGoldenImage.$extension"
        
                        if (!(Test-Path "filesystem::$localPath")) {
                            throw "$localPath does not exist"
                            
                        }
        
                        if (!(Test-Path $tempGI)) {
                            Write-Verbose "Golden Image Path is UNC, caching locally."
                            Copy-Item "filesystem::$localPath" -Destination $tempGI
                        }
                        
                        Copy-Item $tempGI -Destination "$using:diskPath\Disk.$extension"
                    
                    }
                }
                else {
                    throw "UNCCredentialScript did not return a valid PSCredential object"
                }
            }
            elseif ($HyperVServer.GoldenImagePath.StartsWith("http")) {
                $temp = $env:TEMP
                $extension = $HyperVServer.GoldenImageExtension
                $tempGI = "$temp\HyperDeployGoldenImage.$extension"

                if ($HyperVServer.GoldenImagePath.Contains("drive.google")) {
                    $p = & { python -V } 2>&1

                    if ($p -is [System.Management.Automation.ErrorRecord]) {
                        throw "Google Drive file download requires Python and Pip to be installed"
                    }
                    else {
                        pip install gdown
                        Set-Location $temp
                        gdrive $HyperVServer.GoldenImagePath -O "HyperDeployGoldenImage.$extension"
                    }

                }
                else {
                    Invoke-WebRequest -Uri $HyperVServer.GoldenImagePath -OutFile $tempGI
                }
            }
            else {
                Invoke-Command   -ComputerName $HyperVServer.Name { 
                    $localPath = $using:path
                    if (!(Test-Path $localPath)) {
                        throw "$localPath does not exist"
                    }

                    $extension = $localPath.Split('.')[-1]

                    Copy-Item $localPath -Destination "$using:diskPath\Disk.$extension"
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

        Invoke-Command  -ComputerName $HyperVServer.Name { 
            $disk = Get-ChildItem -Path $using:diskPath -Filter "Disk.*" -Recurse -Force 
            $name = $using:VM.Name

            $AddVMHardDiskDriveParams = @{ 
                Path         = $disk[0].FullName
                VMName       = $name
            }

            Add-VMHardDiskDrive @AddVMHardDiskDriveParams
        }
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