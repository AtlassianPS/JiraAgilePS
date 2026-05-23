#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraAgilePS {
    Describe "ConvertTo-Epic" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            $script:epicPayload = [pscustomobject]@{
                id      = 10001
                key     = 'DEL-1'
                name    = 'Launch epic'
                summary = 'Launch the product'
                color   = [pscustomobject]@{ key = 'color_1' }
                done    = $true
                self    = 'https://jira.example.com/rest/agile/1.0/epic/10001'
            }
        }

        Describe "Behavior" {
            BeforeAll {
                $script:result = ConvertTo-Epic -InputObject $epicPayload
            }

            It "returns a typed epic object" {
                $result | Should -BeOfType ([AtlassianPS.JiraAgilePS.Epic])
            }

            It "maps epic properties" {
                $result.Id | Should -Be 10001
                $result.Key | Should -Be 'DEL-1'
                $result.Name | Should -Be 'Launch epic'
                $result.Summary | Should -Be 'Launch the product'
                $result.Color | Should -Be 'color_1'
                $result.Done | Should -BeTrue
                $result.Self.AbsoluteUri | Should -Be 'https://jira.example.com/rest/agile/1.0/epic/10001'
            }

            It "normalizes color object name when key is absent" {
                $payload = [pscustomobject]@{ id = 2; color = [pscustomobject]@{ name = 'green' } }

                (ConvertTo-Epic -InputObject $payload).Color | Should -Be 'green'
            }

            It "accepts pipeline input" {
                $pipelineResult = $epicPayload | ConvertTo-Epic

                $pipelineResult.Key | Should -Be 'DEL-1'
            }
        }
    }
}
