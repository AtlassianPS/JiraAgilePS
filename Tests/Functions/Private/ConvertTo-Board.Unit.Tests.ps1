#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraAgilePS {
    Describe "ConvertTo-Board" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            $script:boardPayload = [pscustomobject]@{
                id   = 7
                name = 'Delivery board'
                type = 'scrum'
                self = 'https://jira.example.com/rest/agile/1.0/board/7'
            }
        }

        Describe "Behavior" {
            BeforeAll {
                $script:result = ConvertTo-Board -InputObject $boardPayload
            }

            It "returns a typed board object" {
                $result | Should -BeOfType ([AtlassianPS.JiraAgilePS.Board])
            }

            It "maps board properties" {
                $result.Id | Should -Be 7
                $result.Name | Should -Be 'Delivery board'
                $result.Type | Should -Be ([AtlassianPS.JiraAgilePS.BoardType]::scrum)
                $result.Self.AbsoluteUri | Should -Be 'https://jira.example.com/rest/agile/1.0/board/7'
            }

            It "accepts pipeline input" {
                $pipelineResult = $boardPayload | ConvertTo-Board

                $pipelineResult.Id | Should -Be 7
            }

            It "maps simple boards returned by Jira Cloud" {
                $simpleBoardPayload = [pscustomobject]@{
                    id   = 8
                    name = 'Project board'
                    type = 'simple'
                    self = 'https://jira.example.com/rest/agile/1.0/board/8'
                }

                $simpleBoard = ConvertTo-Board -InputObject $simpleBoardPayload

                $simpleBoard.Type | Should -Be ([AtlassianPS.JiraAgilePS.BoardType]::simple)
            }
        }
    }
}
