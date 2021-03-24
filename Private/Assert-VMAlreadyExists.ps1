function Assert-VMAlreadyExists {

    Param
    (
        [Parameter(Mandatory)]
        [VM]$VM,
        [string[]]$HyperVServers
    )

    $ExistingVM = $null
    $ExistsOn = $null
    $ExistingCount = 0
    $Name = $VM.Name

    foreach ($hyperVServer in $HyperVServers) {
        $foundVM = Get-VM -ComputerName $hyperVServer -name $VM.Name -ErrorAction SilentlyContinue  
        if ($foundVM) {
            $ExistingCount++
            $ExistsOn = $hyperVServer
            $ExistingVM = $foundVM
            
        }
    }

    if ($ExistingCount -gt 1){
        throw "Found multiple existing VM's called $Name - not supported"
    }
  
    return ($ExistingVM, $ExistsOn)

}