Describe 'Test-DefinitionFile Tests' {

  It 'NewVMDiskSizeBytesAndGoldenImagePathStopsExecution_ShouldThrow' {

    $rootDir = (get-item $PSScriptRoot).Parent.FullName
    . "$rootDir\Private\Test-DefinitionFile"
    . "$rootDir\Private\Classes"


    $defFile = "{
        `"VMs`": [
            {
                `"Name`": `"Test`",
                `"GoldenImagePath`": `"C:\\Test.vhdx`",
                `"NewVMDiskSizeBytes`": `"1GB`"
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
                `"VMHardDiskPath`" : `"C:\\Test`",
                `"GoldenImagePath`": `"C:\\Test.vhx`"
            }
        ]
    }"

    { Test-DefinitionFile -DefinitionJson $defFile } | Should -Throw "Test - GoldenImagePath is not a valid vhdx file"

  }


}