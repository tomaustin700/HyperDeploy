Import-Module .\HyperDeploy.psm1 -Force

Publish-HyperDeploy -DefinitionFile "C:\Users\TomA\source\repos\HyperDeploy\Structure2.json" -Replace  -Force -ContinueOnError -Verbose