# HyperDeploy

## Introduction
HyperDeploy is a Powershell module that allows the use of infrastructure as code (IaC) to create and provision Hyper-V virtual machines.

## Installation
HyperDeploy is not currently cross-platform and will only run on Windows, it can be installed by running the following command:
```powershell
Install-Module -Name HyperDeploy
```

# Usage

The main function provided by HyperDeploy is `Publish-HyperDeploy` which has the following parameters:

### Definition File

```powershell
Publish-HyperDeploy -DefinitionFile "C:\definition.json"
```
The definition file is a json file that instructs Hyper Deploy on the infrastructure changes that you want, it is the code part of infrastructure as code. More information on the definition file can be found below.

### Replace
```powershell
Publish-HyperDeploy -DefinitionFile "C:\definition.json" -Replace
```
If replace is specified then Hyper Deploy will replace any Hyper-V VM's that already exist when `Publish-HyperDeploy` is ran.

### Force
```powershell
Publish-HyperDeploy -DefinitionFile "C:\definition.json" -Force
```
Force will prevent Hyper Deploy prompting for confirmation before carrying out actions, use with care!

### Destroy
```powershell
Publish-HyperDeploy -DefinitionFile "C:\definition.json" -Destroy
```
Destroy will remove all infrastructure specified in the definition file, use with care!

### ReplaceUpFront
```powershell
Publish-HyperDeploy -DefinitionFile "C:\definition.json" -Replace -ReplaceUpFront
```
If replace is set then remove all VM's specified within the definition file in one go before replacing. If not set HyperDeploy will remove and replace one-by-one.

### ContinueOnError
```powershell
Publish-HyperDeploy -DefinitionFile "C:\definition.json" -ContinueOnError
```
Stops HyperDeploy from aborting if an issue is encountered during execution.

# Definition File

Example definition file:
```json
{
    "DeploymentOptions": {
        "StartAfterCreation": true,
        "Parallel": false
    },
    "VMs": [
        {
            "Name": "VM",
            "ProcessorCount": 8,
            "MemoryStartupBytes": "1GB",
            "MemoryMaximumBytes": "4GB",
            "CheckpointType": "Disabled",
            "Replicas": 50,
            "ReplicaStartIndex" : 5,
            "SkipNames": [
                "VM10"
            ],
            "HyperVServers": [
                {
                    "Name": "Host1",
                    "SwitchName": "VM Virtual Switch",
                    "GoldenImagePath": "A:\\goldenimage.vhdx",
                    "VMHardDiskPath": "A:\\Virtual Hard Disks"
                },
                {
                    "Name": "Host2",
                    "SwitchName": "VM Virtual Switch",
                    "GoldenImagePath": "A:\\goldenimage.vhdx",
                    "VMHardDiskPath": "A:\\Virtual Hard Disks",
                    "MaxReplicas" : 20
                }
            ],
            "Provisioning": {
                "RebootAfterEachScript": true,
                "RebootAfterLastScript": true,
                "RebuildOnValidationFailure": true,
                "Scripts": [
                    "C:\\HyperDeployScripts\\Script1.Set-Credential.ps1",
                    "C:\\HyperDeployScripts\\Script2.ps1"
                ]
            }
        }
    ]
}
```

## DeploymentOptions
