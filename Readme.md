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

## Deployment Options
```json
"DeploymentOptions": {
        "StartAfterCreation": true,
        "Parallel": false
    }
```
Deployment options are global settings which rule over all deployments.
### StartAfterCreation
If set to true HyperDeploy will start a VM immediately after the VM has been created. This must be set to true to use the provisioning features of HyperDeploy (discussed below)

### Parallel
If set to true HyperDeploy will attempt to create VM's and provision in parallel to speed up deployment. Up to 5 VM's will be created/provisioned in parallel. This is an experamental feature and has not been thoroughly tested so use with care.

## VMs
VMS is an array of virtual machines that you want to create/destroy using HyperDeploy. See below for an explanation of options that can be set on each VM.

## VM Settings
```json
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

```

### Name
Name of VM you want to create/destroy using HyperDeploy, if `Replicas` is also specified then a number will be suffixed onto the name for each replica created.

### ProcessorCount
Specifies how many virtual processors the VM should be created with.

### MemoryStartupBytes
Specifies how much memory the VM should be assigned at startup.

### MemoryMaximumBytes
Specifies the maximum memory that can be assigned to the VM.

### CheckpointType
Allows setting the VMs checkpoint setting within Hyper-V, for options see below:

The acceptable values for this parameter are:

Disabled. Block creation of checkpoints.
Standard. Create standard checkpoints.
Production. Create production checkpoints if supported by guest operating system. Otherwise, create standard checkpoints.
ProductionOnly. Create production checkpoints if supported by guest operating system. Otherwise, the operation fails.

### Replicas
If set HyperDeploy will create replicas of the VM, this is useful when you have a golden image and want to deploy x amount of replicas. For each replica a number will be suffixed onto the name value. Replicas will be load balanced accross the hosts specified in the `HyperVServers` array (see below).

### ReplicaStartIndex
Used in conjunction with `Replicas`, dictates what the starting replica number should be.

### SkipNames
Use this array to specify any VM's you want to be skipped over when creating replicas. For example if `Name` is set to `VM` and  `Replicas` is set to 3 the following VMs would be created: VM1, VM2 and VM3. If `SkipNames` has `VM2` specified in it like so:
```json
"SkipNames": [
                "VM2"
            ],
```
The VMs created would be VM`, VM3 and VM4.

### HyperVServers
This array contains the details about each Hyper-V host you want to deploy VM's to.
```json
"HyperVServers": [
                {
                    "Name": "Host1",
                    "SwitchName": "VM Virtual Switch",
                    "GoldenImagePath": "A:\\goldenimage.vhdx",
                    "VMHardDiskPath": "A:\\Virtual Hard Disks"
                }
            ]
```
