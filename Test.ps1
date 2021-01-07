Import-Module .\HyperDeploy.psm1 -Force

Publish-HyperDeploy -DefinitionFile "C:\Users\TomA\source\repos\HyperDeploy\Structure3.json" -Replace  -Force -Verbose -Destroy

