function Publish-HyperDeploy {
    [CmdletBinding(SupportsShouldProcess)]
    <#
    .SYNOPSIS
        Infrastructure as Code deployer for Hyper V.

    .DESCRIPTION
        Allows Infrastructure as Code to be used to deploy/remove Hyper V Vitual Machines.

    .PARAMETER DefinitionFile
        Json file containing the VM definitions.

    .PARAMETER Destroy
        Will remove any VM's specified in the definition file

    .PARAMETER Replace
        If a VM already exists that matches a VM declared in the JSON definition file replace the existing VM

    .PARAMETER Force
        WARNING - ONLY USE IF YOU FULLY UNDERSTAND THE RAMIFICATIONS, YOU CAN DO A LOT OF DAMAGE WITH THIS. Prevents any additional prompts from being presented such as confirmation prompts. USING THIS WITH DESTROY IS VERY DANGEROUS AND SHOULD BE AVOIDED

    .PARAMETER Verbose
        Shows more details regarding execution and exceptions
        

    #>

    Param
    (
        [Parameter(Mandatory)]
        [String] $DefinitionFile,
        [Switch] $Replace,
        [Switch] $Force,
        [Switch] $Destroy,
        [Switch] $ReplaceUpFront,
        [Switch] $ContinueOnError

    )

    

    write-host @"


    __  __                          __           __           
   / / / /_  ______  ___  _________/ /__  ____  / /___  __  __
  / /_/ / / / / __ \/ _ \/ ___/ __  / _ \/ __ \/ / __ \/ / / /
 / __  / /_/ / /_/ /  __/ /  / /_/ /  __/ /_/ / / /_/ / /_/ / 
/_/ /_/\__, / .___/\___/_/   \__,_/\___/ .___/_/\____/\__, /  
      /____/_/                        /_/            /____/   


"@

    #Requires -RunAsAdministrator

    try{
        Get-VM
    }catch{
        write-host "Hyper-V module not installed, please install and try again"
        exit
    }


    if ($PSCmdlet.ShouldProcess("Target", "Operation")) {
        $definition = Test-DefinitionFile -DefinitionFile $DefinitionFile

        $servers = @()

    

        foreach ($vm in $definition.VMs) {

            if (!$vm.HyperVServers) {

                $vm.HyperVServers = @()
                $server = New-Object HyperVServer
                $server.Name = $env:computername
                $vm.HyperVServers += $server
            }

            foreach ($server in $vm.HyperVServers) {
                
                if ($null -eq $server.Name){
                    $server.Name = $env:computername
                }
                
                $servers += $server

                if (!$server.MaxReplicas) {
                    $server.MaxReplicas = 9999999
                }
            }
        }

        Test-HyperVServers -HyperVServers ($servers | Get-Unique)
        Publish-VMs -HyperVServers ($servers | Select-Object -ExpandProperty Name | Get-Unique) -VMs $definition.VMs -DeploymentOptions $definition.DeploymentOptions -Replace $Replace  -Force $Force -Destroy $Destroy -ReplaceUpFront $ReplaceUpFront -ContinueOnError $ContinueOnError
        Clear-TempFiles -HyperVServers ($servers | Select-Object -ExpandProperty Name | Get-Unique)
    }

}
