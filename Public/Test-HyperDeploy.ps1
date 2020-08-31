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
