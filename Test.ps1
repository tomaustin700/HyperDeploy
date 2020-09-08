Import-Module .\HyperDeploy.psm1


Publish-HyperDeploy -DefinitionFile "C:\Users\TomA\source\repos\HyperDeploy\Structure.json" -Verbose 

Get-Module | Remove-Module