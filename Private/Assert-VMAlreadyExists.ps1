function Assert-VMAlreadyExists {

    Param
    (
        [Parameter(Mandatory)]
        [VM]$VM,
        [HyperVServer[]]$HyperVServers
    )

    $ExistingVM = $null
    $ExistsOn = $null
    $ExistingCount = 0
    $Name = $VM.Name

    foreach ($hyperVServer in $HyperVServers) {
        $ExistingVM = Get-VM -ComputerName $hyperVServer.Name -name $VM.Name -ErrorAction SilentlyContinue  
        if ($ExistingVM) {
            $ExistingCount++
            $ExistsOn = $hyperVServer.Name
            
        }
    }

    if ($ExistingCount -gt 1){
        break "Found multiple existing VM's called $Name - not supported"
    }
  
    return ($ExistingVM, $ExistsOn)

}