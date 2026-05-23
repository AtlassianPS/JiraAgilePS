#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraAgilePS {
    Describe "ConvertTo-Sprint" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            $script:sprintPayload = [pscustomobject]@{
                id            = 25
                name          = 'Sprint 25'
                state         = 'active'
                startDate     = '2026-05-01T08:00:00.000Z'
                endDate       = '2026-05-15T08:00:00.000Z'
                completeDate  = '2026-05-16T08:00:00.000Z'
                originBoardId = 7
                goal          = 'Ship the board fixes'
                self          = 'https://jira.example.com/rest/agile/1.0/sprint/25'
            }
        }

        Describe "Behavior" {
            BeforeAll {
                $script:result = ConvertTo-Sprint -InputObject $sprintPayload
            }

            It "returns a typed sprint object" {
                $result | Should -BeOfType ([AtlassianPS.JiraAgilePS.Sprint])
            }

            It "maps sprint properties" {
                $result.Id | Should -Be 25
                $result.Name | Should -Be 'Sprint 25'
                $result.State | Should -Be ([AtlassianPS.JiraAgilePS.SprintState]::active)
                $result.OriginBoardId | Should -Be 7
                $result.Goal | Should -Be 'Ship the board fixes'
                $result.Self.AbsoluteUri | Should -Be 'https://jira.example.com/rest/agile/1.0/sprint/25'
            }

            It "normalizes date values" {
                $result.StartDate | Should -BeOfType ([System.DateTime])
                $result.EndDate | Should -BeOfType ([System.DateTime])
                $result.CompleteDate | Should -BeOfType ([System.DateTime])
            }

            It "accepts pipeline input" {
                $pipelineResult = $sprintPayload | ConvertTo-Sprint

                $pipelineResult.Id | Should -Be 25
            }
        }
    }
}
