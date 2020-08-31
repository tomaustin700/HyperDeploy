function Publish-HyperDeploy
{
    <#
    .SYNOPSIS
        Infrastructure as Code deployer for Hyper V.

    .DESCRIPTION
        Allows Infrastructure as Code to be used to deploy and .

    .PARAMETER Url
        The URL from which the binary will be downloaded. Required parameter.

    .PARAMETER Name
        The Name with which binary will be downloaded. Required parameter.

    .PARAMETER ArgumentList
        The list of arguments that will be passed to the installer. Required for .exe binaries.

    .EXAMPLE
        Install-Binary -Url "https://go.microsoft.com/fwlink/p/?linkid=2083338" -Name "winsdksetup.exe" -ArgumentList ("/features", "+", "/quiet")
    #>

    Param
    (
        [Parameter(Mandatory)]
        [String] $Url,
        [Parameter(Mandatory)]
        [String] $Name,
        [String[]] $ArgumentList
    )

}