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

    .PARAMETER PostCreateScript
        Windows Only - Powershell script to run once VM has been created and Win RM can connect. Main use if for when deploying a Packer image to do further configuration once VM deployed.

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
        [String] $PostCreateScript,
        [Switch] $Clean,
        [Switch] $Force 
    )

    #Requires -RunAsAdministrator

    if ($PSCmdlet.ShouldProcess("Target", "Operation")){
        $definition = Test-DefinitionFile $DefinitionFile
        #Test-HyperVServerConnectivity -HyperVServers $definition.HyperVServers
        Publish-VMs -HyperVServers $definition.HyperVServers -VMs $definition.VMs -Replace $Replace -Clean $Clean -Force $Force
    }

}
