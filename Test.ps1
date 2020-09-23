Import-Module .\HyperDeploy.psm1 -Force

[string]$userName = 'automation'
[string]$userPassword = 'redacted'
[securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
[pscredential]$credOject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)


Publish-HyperDeploy -DefinitionFile "C:\Users\TomA\source\repos\HyperDeploy\Structure1.json"  -Replace  -ProvisionCredential $credOject -Force -verbose

