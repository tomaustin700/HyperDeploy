function Publish-HyperDeploy {
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

    .PARAMETER Strict
        WARNING - ONLY USE IF YOU FULLY UNDERSTAND THE RAMIFICATIONS, YOU CAN DO A LOT OF DAMAGE WITH THIS. Will remove any pre-existing VM's that are not declared the in VM Definition file.

    .PARAMETER Force
        WARNING - ONLY USE IF YOU FULLY UNDERSTAND THE RAMIFICATIONS, YOU CAN DO A LOT OF DAMAGE WITH THIS. Prevents any additional prompts from being presented such as confirmation prompts. USING THIS WITH STRICT IS VERY DANGEROUS AND SHOULD BE AVOIDED

    #>

    Param
    (
        [Parameter(Mandatory)]
        [String] $DefinitionFile,
        [bool] $Replace,
        [String] $PostCreateScript,
        [bool] $Strict,
        [bool] $Force
    )

}

function Test-HyperDeploy {
    <#
    .SYNOPSIS
        Infrastructure as Code deployer for Hyper V.

    .DESCRIPTION
        Shows changes that will be made with specified definition file and paramters.

    .PARAMETER DefinitionFile
        Json file containing the VM definitions.

    .PARAMETER Replace
        If a VM already exists that matches a VM declared in the JSON definition file replace the existing VM

    .PARAMETER Strict
        WARNING - ONLY USE IF YOU FULLY UNDERSTAND THE RAMIFICATIONS, YOU CAN DO A LOT OF DAMAGE WITH THIS. Will remove any pre-existing VM's that are not declared the in VM Definition file.

    #>

    Param
    (
        [Parameter(Mandatory)]
        [String] $DefinitionFile,
        [bool] $Replace,
        [bool] $Strict
    )

}