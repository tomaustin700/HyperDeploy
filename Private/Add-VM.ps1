function Add-VM {
    Param
    (
        [Parameter(Mandatory)]
        [VM]$VM,
        [HyperVServer]$HyperVServer
    )
    
    $NewVMParams = @{ 
        Name               = $VM.Name
        MemoryStartupBytes = [int64][scriptblock]::Create($VM.MemoryStartupBytes).Invoke()[0] 
    }

    if ($VM.SwitchName) {
        $NewVMParams.Add("SwitchName", $VM.SwitchName)
    }

    $SetVMParams = @{ 
        Name               = $VM.Name
        ProcessorCount     = $VM.ProcessorCount
        MemoryMaximumBytes = [int64][scriptblock]::Create($VM.MemoryMaximumBytes).Invoke()[0]  
    }

    if ($VM.CheckpointType) {
        $SetVMParams.Add("CheckpointType", $VM.CheckpointType)
    }

    if ($HyperVServer) {
        $NewVMParams.Add("ComputerName", $HyperVServer.Name)
        $SetVMParams.Add("ComputerName", $HyperVServer.Name)
    }

    New-VM  @NewVMParams
    Set-VM @SetVMParams

    if ($VM.VMHardDiskPath) {

        $diskPath = $VM.VMHardDiskPath + "\" + $VM.Name

        if ($HyperVServer) {
            Invoke-Command -ComputerName $HyperVServer.Name { 
                if (!(Test-Path -Path $using:diskPath)) {
                    New-Item -ItemType directory -Path $using:diskPath -Force
                }
            } 
        }
        else {
            New-Item -ItemType directory -Path $diskPath -Force
        }

        if ($VM.GoldenImagePath) {
            $path = $VM.GoldenImagePath

            if ($HyperVServer) {
                Invoke-Command -ComputerName $HyperVServer.Name { 
                    $localPath = $using:path
                    if ($localPath.StartsWith("\\")) {

                        $temp = $env:TEMP
                        $tempGI = "$temp\HyperDeployGoldenImage.vhdx"
    
                        if (!Test-Path "filesystem::$localPath") {
                            Write-Host "$path does not exist"
                            exit 1
                        }
    
                        if (!Test-Path $tempGI) {
                            Write-Host "Golden Image Path is UNC, caching locally."
                            Copy-Item $VM.GoldenImagePath -Destination $tempGI
                        }
    
                        Copy-Item $tempGI -Destination "$diskPath\Disk.vhdx"
                    }
                    else {
    
                        if (!Test-Path $path) {
                            Write-Host "$path does not exist"
                            exit 1
                        }
    
                        Copy-Item $VM.GoldenImagePath -Destination "$diskPath\Disk.vhdx"
                    }

                } 

            }
            else {

                if ($VM.GoldenImagePath.StartsWith("\\")) {

                    $temp = $env:TEMP
                    $tempGI = "$temp\HyperDeployGoldenImage.vhdx"

                    if (!Test-Path "filesystem::$path") {
                        Write-Host "$path does not exist"
                        exit 1
                    }

                    if (!Test-Path $tempGI) {
                        Write-Host "Golden Image Path is UNC, caching locally."
                        Copy-Item $VM.GoldenImagePath -Destination $tempGI
                    }

                    Copy-Item $tempGI -Destination "$diskPath\Disk.vhdx"
                }
                else {

                    if (!Test-Path $path) {
                        Write-Host "$path does not exist"
                        exit 1
                    }

                    Copy-Item $VM.GoldenImagePath -Destination "$diskPath\Disk.vhdx"
                }
            } 
        }
        elseif ($VM.NewVMDiskSizeBytes) {

            $NewVHDParams = @{ 
                Path      = "$diskPath\Disk.vhdx"
                SizeBytes = [int64][scriptblock]::Create($VM.NewVMDiskSizeBytes).Invoke()[0]
            }

            if ($HyperVServer) {
                $NewVHDParams.Add("ComputerName", $HyperVServer.Name)
            }

            New-VHD @NewVHDParams
        }

        $AddVMHardDiskDriveParams = @{ 
            Path   = "$diskPath\Disk.vhdx"
            VMName = $VM.Name
        }

        if ($HyperVServer) {
            $AddVMHardDiskDriveParams.Add("ComputerName", $HyperVServer.Name)
        }

        Add-VMHardDiskDrive @AddVMHardDiskDriveParams
    }

}