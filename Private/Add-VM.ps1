function Add-VM {
    Param
    (
        [Parameter(Mandatory)]
        [VM]$VM,
        [HyperVServer]$HyperVServer
    )
    
    Write-Host $HyperVServer.Name
    Write-Host $VM.Name

    $NewVMParams = @{ 
        Name = $VM.Name
        MemoryStartupBytes = [int64][scriptblock]::Create($VM.MemoryStartupBytes).Invoke()[0] 
    }

    if ($VM.SwitchName){
        $NewVMParams.Add("SwitchName", $VM.SwitchName)
    }

    $SetVMParams = @{ 
        Name = $VM.Name
        ProcessorCount = $VM.ProcessorCount
        MemoryMaximumBytes =  [int64][scriptblock]::Create($VM.MemoryMaximumBytes).Invoke()[0]  
    }

    if ($VM.CheckpointType){
        $SetVMParams.Add("CheckpointType", $VM.CheckpointType)
    }

    if ($HyperVServer.Name){
        $NewVMParams.Add("ComputerName", $HyperVServer.Name)
        $SetVMParams.Add("ComputerName", $HyperVServer.Name)
    }

    New-vm  @NewVMParams
    Set-vm @SetVMParams

    if ($VM.GoldenImagePath){

    }

}