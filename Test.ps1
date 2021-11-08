Import-Module .\HyperDeploy.psm1 -Force

Publish-HyperDeploy -DefinitionFile "C:\Users\TomA\source\repos\HyperDeploy\WinServer.json" -Replace  -Force -Verbose -ReplaceUpFront 
