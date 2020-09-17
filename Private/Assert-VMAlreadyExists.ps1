function Assert-VMAlreadyExists {

    $rootDir = (get-item $PSScriptRoot).Parent.FullName
    . "$rootDir\Private\Classes"

    Param
    (
        [Parameter(Mandatory)]
        [VM]$VM,
        [HyperVServer[]]$HyperVServers
    )

    $ExistingVM = $null
    $ExistsOn = $null

    foreach ($hyperVServer in $HyperVServers) {
        $ExistingVM = Get-VM -ComputerName $hyperVServer.Name -name $VM.Name -ErrorAction SilentlyContinue  
        if ($ExistingVM) {
            $ExistsOn = $hyperVServer.Name
            break
        }
    }
  
    return ($ExistingVM, $ExistsOn)

}