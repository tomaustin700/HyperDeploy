function Test-DefinitionFile {
    Param
    (
        [string]$DefinitionFile,
        [string]$DefinitionJson
    )

    Write-Verbose "Parsing and validating defintion..."
   
    if ($DefinitionFile) {
        $definition = [Definition](Get-Content $DefinitionFile -Raw | Out-String | ConvertFrom-Json)
    }
    elseif ($DefinitionJson) {
        $definition = [Definition]($DefinitionJson | ConvertFrom-Json)
    }

    if (!$definition){
        throw "Invalid definition file"
    }

    foreach ($definitionVM in $definition.VMs) {
        $name = $definitionVM.Name

        foreach($server in $definitionVM.HyperVServers){
            if ($definitionVM.NewVMDiskSizeBytes -and $server.GoldenImagePath) {
                throw "$name - NewVMDiskSizeBytes and GoldenImagePath set, only one must be specified"
            }
        }

        foreach($server in $definitionVM.HyperVServers){
            if ($server.GoldenImagePath -and !$server.GoldenImagePath.StartsWith("http") -and !$server.GoldenImagePath.ToLower().EndsWith("vhdx") -and !$server.GoldenImagePath.ToLower().EndsWith("vhd")) {
                throw "$name - GoldenImagePath is not a valid vhd/vhdx file"
            }
        }

        foreach($server in $definitionVM.HyperVServers){
            if ($server.GoldenImagePath -and $server.GoldenImagePath.ToLower().StartsWith("filesystem")) {
                throw "$name - GoldenImagePath is not a valid UNC path, UNC paths should start with \\"
            }
        }

        foreach($server in $definitionVM.HyperVServers){
            if ($server.GoldenImagePath -and $server.GoldenImagePath.StartsWith("http") -and !$server.GoldenImageExtension) {
                throw "$name - GoldenImageExtension must be provided when using a URL image path"
            }
        }

        foreach($server in $definitionVM.HyperVServers){
            if ($server.GoldenImagePath  -and $server.GoldenImagePath.StartsWith("\\") -and !$definitionVM.UNCCredentialScript) {
                throw "$name - UNCCredentialScript is required when GoldenImagePath is a UNC path"
            }
        }

        foreach($server in $definitionVM.HyperVServers){
            if ($server.GoldenImagePath  -and $server.GoldenImagePath.StartsWith("\\") -and $definitionVM.UNCCredentialScript -and !$definitionVM.UNCCredentialScript.ToLower().EndsWith("ps1")) {
                throw "$name - UNCCredentialScript must be a valid ps1 script"
            }
        }

        foreach($server in $definitionVM.HyperVServers){
            if (!$server.VMHardDiskPath -and ($definitionVM.NewVMDiskSizeBytes -Or $server.GoldenImagePath)) {
                throw "$name - You must specify VMHardDiskPath when setting NewVMDiskSizeBytes or GoldenImagePath"
            }
        }
           
        if ($definitionVM.Provisioning) {
            if ($definitionVM.Provisioning.Scripts -and $definitionVM.Provisioning.Scripts.Length -gt 0) {
                foreach($server in $definitionVM.HyperVServers){
                    if (!$server.GoldenImagePath){
                        throw "$name - Provision Scripts can only be used if GoldenImagePath set"

                    }
                }
            }

            if ($definitionVM.Provisioning.Scripts -and $definitionVM.Provisioning.Scripts.Length -gt 0) {
                foreach($server in $definitionVM.HyperVServers){
                    if (!$server.SwitchName){
                        throw "$name - Provision Scripts can only be used if SwitchName set"

                    }
                }
            }
    
            if ($definitionVM.Provisioning.Scripts -and $definitionVM.Provisioning.Scripts.Length -gt 0 -and !$definition.DeploymentOptions.StartAfterCreation) {
                throw "$name - Provision Scripts can only be used if DeploymentOptions.StartAfterCreation is true"
            }
            elseif ($definitionVM.Provisioning.Scripts -and $definitionVM.Provisioning.Scripts.Length -gt 0 -and $definition.DeploymentOptions.StartAfterCreation) {
                foreach ($script in $definitionVM.Provisioning.Scripts) {
                    if (!$script.EndsWith("ps1")) {
                        throw "$name - $script - Provision Script must be a valid ps1 file"

                    }
                } 
            }
        }

           

    }

   
        

    Write-Host "Definition Valid" -ForegroundColor Green
   

    return $definition
}