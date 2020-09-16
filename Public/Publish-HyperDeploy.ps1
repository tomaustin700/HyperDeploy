function Publish-HyperDeploy {
    [CmdletBinding(SupportsShouldProcess)]
    <#
    .SYNOPSIS
        Infrastructure as Code deployer for Hyper V.

    .DESCRIPTION
        Allows Infrastructure as Code to be used to deploy/remove Hyper V Vitual Machines.

    .PARAMETER DefinitionFile
        Json file containing the VM definitions.

    .PARAMETER Replace
        If a VM already exists that matches a VM declared in the JSON definition file replace the existing VM

    .PARAMETER Clean
        WARNING - ONLY USE IF YOU FULLY UNDERSTAND THE RAMIFICATIONS, YOU CAN DO A LOT OF DAMAGE WITH THIS. Will remove any pre-existing VM's that are not declared the in VM Definition file.

    .PARAMETER Force
        WARNING - ONLY USE IF YOU FULLY UNDERSTAND THE RAMIFICATIONS, YOU CAN DO A LOT OF DAMAGE WITH THIS. Prevents any additional prompts from being presented such as confirmation prompts. USING THIS WITH CLEAN IS VERY DANGEROUS AND SHOULD BE AVOIDED

    .PARAMETER Verbose
        Shows more details regarding execution and exceptions
        

    #>

    Param
    (
        [Parameter(Mandatory)]
        [String] $DefinitionFile,
        [Switch] $Replace,
        [Switch] $Clean,
        [Switch] $Force 
    )

    #Requires -RunAsAdministrator

    if ($PSCmdlet.ShouldProcess("Target", "Operation")) {
        $definition = Test-DefinitionFile $DefinitionFile

        if (!$definition.HyperVServers -or $definition.HyperVServers.Count -gt 0) {
            $definition.HyperVServers = @()
            $definition.HyperVServers += [HyperVServer]@{name = $env:computername }
        }

        foreach ($hyperVServer in $definition.HyperVServers) {
            if (!$hyperVServer.MaxVMCount) {
                $hyperVServer.MaxVMCount = 9999999
            }
        }

        Test-HyperVServerConnectivity -HyperVServers $definition.HyperVServers
        Publish-VMs -HyperVServers $definition.HyperVServers -VMs $definition.VMs -DeploymentOptions $definition.DeploymentOptions -Replace $Replace -Clean $Clean -Force $Force
        Clear-TempFiles -HyperVServers $definition.HyperVServers 
    }

}
