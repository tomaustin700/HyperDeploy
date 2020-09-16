function Test-DefinitionFile {
    Param
    (
        [Parameter(Mandatory)]
        [string]$DefinitionFile
    )

    Write-Host "Parsing and validating defintion..." -ForegroundColor Yellow
    try {
        $definition = [Definition](Get-Content $DefinitionFile -Raw | Out-String | ConvertFrom-Json)

        $issues = @()
        foreach ($definitionVM in $definition.VMs) {
            $name = $definitionVM.Name
            
            if ($definitionVM.NewVMDiskSizeBytes -and $definitionVM.GoldenImagePath) {
                $issues += "$name - NewVMDiskSizeBytes and GoldenImagePath set, only one must be specified"
            }

            if ($definitionVM.GoldenImagePath -and !$definitionVM.GoldenImagePath.ToLower().EndsWith("vhdx")) {
                $issues += "$name - GoldenImagePath is not a valid vhdx file"
            }

            if ($definitionVM.GoldenImagePath -and $definitionVM.GoldenImagePath.ToLower().StartsWith("filesystem")) {
                $issues += "$name - GoldenImagePath is not a valid UNC path, UNC paths should start with \\"
            }

            if (!$definitionVM.VMHardDiskPath -and ($definitionVM.NewVMDiskSizeBytes -Or $definitionVM.GoldenImagePath)){
                $issues += "$name - You must specify VMHardDiskPath when setting NewVMDiskSizeBytes or GoldenImagePath"
            }

            if ($definitionVM.ProvisionScript -and !$definitionVM.GoldenImagePath){
                $issues += "$name - ProvisionScript can only be used if GoldenImagePath set"
            }

            if ($definitionVM.ProvisionScript -and !$definition.DeploymentOptions.StartAfterCreation){
                $issues += "$name - ProvisionScript can only be used if DeploymentOptions.StartAfterCreation is true"
            }
            elseif ($definitionVM.ProvisionScript -and $definition.DeploymentOptions.StartAfterCreation -and !$definitionVM.ProvisionScript.ToLower().EndsWith("psd1"))
            {
                $issues += "$name - ProvisionScript must be a valid ps1 file"
            }

        }

        if ($issues.Length -gt 0) {
            foreach ($issue in $issues) {
                Write-Host -ForegroundColor Red $issue
            }

            exit 1
        }
        

        Write-Host "Definition Valid" -ForegroundColor Green
    }
    catch {
        Write-Host "Invalid definition file" -ForegroundColor Red
        Write-Host $_.Exception

        exit 1
        
    }

    return $definition
}