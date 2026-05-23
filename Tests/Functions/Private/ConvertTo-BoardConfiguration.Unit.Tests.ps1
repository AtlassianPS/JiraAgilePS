#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraAgilePS {
    Describe "ConvertTo-BoardConfiguration" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            $script:configurationPayload = [pscustomobject]@{
                id       = 42
                name     = 'Delivery configuration'
                location = [pscustomobject]@{
                    projectKey = 'DEL'
                }
            }
        }

        Describe "Behavior" {
            It "adds the board configuration type name" {
                $result = ConvertTo-BoardConfiguration -InputObject $configurationPayload

                $result.PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraAgilePS.BoardConfiguration'
            }

            It "preserves payload properties" {
                $result = ConvertTo-BoardConfiguration -InputObject $configurationPayload

                $result.id | Should -Be 42
                $result.name | Should -Be 'Delivery configuration'
                $result.location.projectKey | Should -Be 'DEL'
            }

            It "ignores null pipeline input" {
                $result = $null | ConvertTo-BoardConfiguration

                $result | Should -BeNullOrEmpty
            }
        }
    }
}
