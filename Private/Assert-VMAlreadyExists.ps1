function Assert-VMAlreadyExists {
    Param
    (
        [Parameter(Mandatory)]
        [VM]$VM,
        [HyperVServer[]]$HyperVServers
    )

    $ExistingVM = $null
    $ExistsOn = $null

    if ($HyperVServers.Count -gt 0) {
        
        foreach ($hyperVServer in $HyperVServers) {
            $ExistingVM = Get-VM -ComputerName $hyperVServer.Name -name $VM.Name -ErrorAction SilentlyContinue  
            $ExistsOn = $hyperVServer.Name
            if ($Exists){
                break
            }
        }
    }
    else {
        $ExistingVM = get-vm -name $VM.Name -ErrorAction SilentlyContinue  
        if ($ExistingVM){
            $ExistsOn = $env:COMPUTERNAME
        }
    }

    return ($ExistingVM, $ExistsOn)

}