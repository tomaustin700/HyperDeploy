Describe 'Test-DefinitionFile Tests' {

  It 'NewVMDiskSizeBytesAndGoldenImagePathStopsExecution_ShouldThrow' {

    $rootDir = (get-item $PSScriptRoot).Parent.FullName
    . "$rootDir\Private\Test-DefinitionFile"
    . "$rootDir\Private\Classes"


    $defFile = "{
        `"VMs`": [
            {
                `"Name`": `"Test`",
                `"NewVMDiskSizeBytes`": `"1GB`",
                `"HyperVServers`": [
                  {
                      `"GoldenImagePath`": `"C:\\Test.vhdx`",
                  }
              ]
            }
        ]
    }"

    { Test-DefinitionFile -DefinitionJson $defFile } | Should -Throw "Test - NewVMDiskSizeBytes and GoldenImagePath set, only one must be specified"

  }

  It 'GoldenImageCanOnlyBeVHDX_ShouldThrow' {

    $rootDir = (get-item $PSScriptRoot).Parent.FullName
    . "$rootDir\Private\Test-DefinitionFile"
    . "$rootDir\Private\Classes"


    $defFile = "{
        `"VMs`": [
            {
                `"Name`": `"Test`",
                `"HyperVServers`": [
                  {
                      `"GoldenImagePath`": `"C:\\Test`",
                      `"VMHardDiskPath`" : `"C:\\Test`"
                  }
              ]
            }
        ]
    }"

    { Test-DefinitionFile -DefinitionJson $defFile } | Should -Throw "Test - GoldenImagePath is not a valid vhdx file"

  }

  It 'GoldenImagePathHasToBeValidUNCPath_ShouldThrow' {

    $rootDir = (get-item $PSScriptRoot).Parent.FullName
    . "$rootDir\Private\Test-DefinitionFile"
    . "$rootDir\Private\Classes"


    $defFile = "{
        `"VMs`": [
            {
                `"Name`": `"Test`",
                `"HyperVServers`": [
                  {
                      `"GoldenImagePath`": `"filesystem:\\server\\c$\\Test.vhdx`",
                      `"VMHardDiskPath`" : `"C:\\Test`"
                  }
              ]
                
            }
        ]
    }"

    { Test-DefinitionFile -DefinitionJson $defFile } | Should -Throw "Test - GoldenImagePath is not a valid UNC path, UNC paths should start with \\"

  }

  It 'VMHardDiskPathMustBeSetWhenSpecifyingNewVMDiskSizeBytes_ShouldThrow' {

    $rootDir = (get-item $PSScriptRoot).Parent.FullName
    . "$rootDir\Private\Test-DefinitionFile"
    . "$rootDir\Private\Classes"


    $defFile = "{
        `"VMs`": [
            {
                `"Name`": `"Test`",
                `"NewVMDiskSizeBytes`": `"1GB`",
                `"HyperVServers`": [
                  {
                      
                  }
              ]
            }
        ]
    }"

    { Test-DefinitionFile -DefinitionJson $defFile } | Should -Throw "Test - You must specify VMHardDiskPath when setting NewVMDiskSizeBytes or GoldenImagePath"

  }

  It 'VMHardDiskPathMustBeSetWhenSpecifyingGoldenImagePath_ShouldThrow' {

    $rootDir = (get-item $PSScriptRoot).Parent.FullName
    . "$rootDir\Private\Test-DefinitionFile"
    . "$rootDir\Private\Classes"


    $defFile = "{
        `"VMs`": [
            {
                `"Name`": `"Test`",
                `"HyperVServers`": [
                  {
                      `"GoldenImagePath`": `"C:\\Test.vhdx`",
                  }
              ]
            }
        ]
    }"

    { Test-DefinitionFile -DefinitionJson $defFile } | Should -Throw "Test - You must specify VMHardDiskPath when setting NewVMDiskSizeBytes or GoldenImagePath"

  }

  It 'SpecifyingProvisionScriptsRequiresGoldenImagePathToBeSet_ShouldThrow' {

    $rootDir = (get-item $PSScriptRoot).Parent.FullName
    . "$rootDir\Private\Test-DefinitionFile"
    . "$rootDir\Private\Classes"


    $defFile = "{
        `"VMs`": [
            {
                `"Name`": `"Test`",
                `"HyperVServers`": [
                  {
                      `"SwitchName`": `"Test`",
                  }
                  ],
                `"Provisioning`" : {
                  `"Scripts`": [
                      `"C:\\Test.ps1`"
                  ] 
              }
            }
        ]
    }"

    { Test-DefinitionFile -DefinitionJson $defFile } | Should -Throw "Test - Provision Scripts can only be used if GoldenImagePath set"

  }

  It 'SpecifyingProvisionScriptsRequiresSwitchNameToBeSet_ShouldThrow' {

    $rootDir = (get-item $PSScriptRoot).Parent.FullName
    . "$rootDir\Private\Test-DefinitionFile"
    . "$rootDir\Private\Classes"


    $defFile = "{
        `"VMs`": [
            {
                `"Name`": `"Test`",
                `"HyperVServers`": [
                  {
                      `"GoldenImagePath`": `"C:\\Test.vhdx`",
                      `"VMHardDiskPath`" : `"C:\\Test`"
                  }
              ],
                
                `"Provisioning`" : {
                  `"Scripts`": [
                      `"C:\\Test.ps1`"
                  ] 
              }
            }
        ]
    }"

    { Test-DefinitionFile -DefinitionJson $defFile } | Should -Throw "Test - Provision Scripts can only be used if SwitchName set"

  }

  It 'SpecifyingProvisionScriptsRequiresDeploymentOptionsStartAfterCreate_ShouldThrow' {

    $rootDir = (get-item $PSScriptRoot).Parent.FullName
    . "$rootDir\Private\Test-DefinitionFile"
    . "$rootDir\Private\Classes"

    $defFile = "{
      `"DeploymentOptions`": {
             `"StartAfterCreation`": false
             },
      `"VMs`": [
          {
              `"Name`": `"Test`",
              `"HyperVServers`": [
                {
                    `"GoldenImagePath`": `"C:\\Test.vhdx`",
                    `"VMHardDiskPath`" : `"C:\\Test`",
                    `"SwitchName`" : `"Test`"
                }
            ],
              `"Provisioning`" : {
                `"Scripts`": [
                    `"C:\\Test.ps1`"
                ] 
            }
          }
      ]
  }"

    { Test-DefinitionFile -DefinitionJson $defFile } | Should -Throw "Test - Provision Scripts can only be used if DeploymentOptions.StartAfterCreation is true"

  }

  It 'ProvisionScriptsMustHavePS1Extension_ShouldThrow' {

    $rootDir = (get-item $PSScriptRoot).Parent.FullName
    . "$rootDir\Private\Test-DefinitionFile"
    . "$rootDir\Private\Classes"

    $defFile = "{
      `"DeploymentOptions`": {
             `"StartAfterCreation`": false
             },
      `"VMs`": [
          {
              `"Name`": `"Test`",
              `"HyperVServers`": [
                {
                    `"GoldenImagePath`": `"C:\\Test.vhdx`",
                    `"VMHardDiskPath`" : `"C:\\Test`",
                    `"SwitchName`" : `"Test`"
                }
            ],
              `"Provisioning`" : {
                `"Scripts`": [
                    `"C:\\Test.exe`"
                ] 
            }
          }
      ]
  }"

    { Test-DefinitionFile -DefinitionJson $defFile } | Should -Throw "Test - Provision Scripts can only be used if DeploymentOptions.StartAfterCreation is true"

  }

  It 'UNCCredentialScriptRequiredWhenGoldenImagePathIsUNC_ShouldThrow' {

    $rootDir = (get-item $PSScriptRoot).Parent.FullName
    . "$rootDir\Private\Test-DefinitionFile"
    . "$rootDir\Private\Classes"


    $defFile = "{
        `"VMs`": [
            {
                `"Name`": `"Test`",
                `"HyperVServers`": [
                  {
                      `"GoldenImagePath`": `"\\\\UNC\\Test.vhdx`",
                      `"VMHardDiskPath`" : `"C:\\Test`"
                  }
              ],
                
              
            }
        ]
    }"

    { Test-DefinitionFile -DefinitionJson $defFile } | Should -Throw "Test - UNCCredentialScript is required when GoldenImagePath is a UNC path"

  }

  It 'UNCCredentialScriptCanOnlyBePS1Script_ShouldThrow' {

    $rootDir = (get-item $PSScriptRoot).Parent.FullName
    . "$rootDir\Private\Test-DefinitionFile"
    . "$rootDir\Private\Classes"


    $defFile = "{
        `"VMs`": [
            {
                `"Name`": `"Test`",
                `"HyperVServers`": [
                  {
                      `"GoldenImagePath`": `"\\\\UNC\\Test.vhdx`",
                      `"VMHardDiskPath`" : `"C:\\Test`"
                  }
              ],
                `"UNCCredentialScript`": `"Test`"
                
              
            }
        ]
    }"

    { Test-DefinitionFile -DefinitionJson $defFile } | Should -Throw "Test - UNCCredentialScript must be a valid ps1 script"

  }


}