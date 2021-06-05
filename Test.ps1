Import-Module .\HyperDeploy.psm1 -Force

Publish-HyperDeploy -DefinitionFile "C:\Users\Tom\source\repos\HyperDeploy\Structure.json" -Replace  -Force -Verbose 
