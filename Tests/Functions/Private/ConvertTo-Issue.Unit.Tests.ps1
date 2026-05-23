#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraAgilePS {
    Describe "ConvertTo-Issue" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            $script:issuePayload = [pscustomobject]@{
                id     = '10010'
                key    = 'DEL-10'
                fields = [pscustomobject]@{
                    summary = 'Fix board view'
                }
            }
        }

        Describe "Behavior" {
            It "adds the Agile issue type name" {
                $result = ConvertTo-Issue -InputObject $issuePayload

                $result.PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraAgilePS.Issue'
            }

            It "preserves all payload properties" {
                $result = ConvertTo-Issue -InputObject $issuePayload

                $result.id | Should -Be '10010'
                $result.key | Should -Be 'DEL-10'
                $result.fields.summary | Should -Be 'Fix board view'
            }

            It "ignores null pipeline input" {
                $result = $null | ConvertTo-Issue

                $result | Should -BeNullOrEmpty
            }
        }
    }
}
