function Test-DefinitionFile {
    Param
    (
        [string]$DefinitionFile,
        [string]$DefinitionJson
    )

    Write-Host "Parsing and validating defintion..." -ForegroundColor Yellow
   
    if ($DefinitionFile) {
        $definition = [Definition](Get-Content $DefinitionFile -Raw | Out-String | ConvertFrom-Json)
    }
    elseif ($DefinitionJson) {
        $definition = [Definition]($DefinitionJson | ConvertFrom-Json)
    }

    if (!$definition){
        break "Invalid definition file"
    }

    foreach ($definitionVM in $definition.VMs) {
        $name = $definitionVM.Name
            
        if ($definitionVM.NewVMDiskSizeBytes -and $definitionVM.GoldenImagePath) {
            throw "$name - NewVMDiskSizeBytes and GoldenImagePath set, only one must be specified"
        }

        if ($definitionVM.GoldenImagePath -and !$definitionVM.GoldenImagePath.ToLower().EndsWith("vhdx")) {
            throw "$name - GoldenImagePath is not a valid vhdx file"
        }

        if ($definitionVM.GoldenImagePath -and $definitionVM.GoldenImagePath.ToLower().StartsWith("filesystem")) {
            throw "$name - GoldenImagePath is not a valid UNC path, UNC paths should start with \\"
        }

        if (!$definitionVM.VMHardDiskPath -and ($definitionVM.NewVMDiskSizeBytes -Or $definitionVM.GoldenImagePath)) {
            throw "$name - You must specify VMHardDiskPath when setting NewVMDiskSizeBytes or GoldenImagePath"
        }

        if ($definitionVM.Provisioning) {
            if ($definitionVM.Provisioning.Scripts -and $definitionVM.Provisioning.Scripts.Length -gt 0 -and !$definitionVM.GoldenImagePath) {
                throw "$name - Provision Scripts can only be used if GoldenImagePath set"
            }

            if ($definitionVM.Provisioning.Scripts -and $definitionVM.Provisioning.Scripts.Length -gt 0 -and !$definitionVM.SwitchName) {
                throw "$name - Provision Scripts can only be used if SwitchName set"
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