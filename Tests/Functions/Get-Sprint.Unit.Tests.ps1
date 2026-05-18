#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraAgilePS {
    Describe "Get-JiraAgileSprint" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/TestTools.ps1"
            $script:jiraServer = "https://jira.example.com"

            Mock Get-JiraConfigServer -ModuleName JiraAgilePS {
                $jiraServer
            }
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name "Get-JiraAgileSprint"
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = "Sprint"; type = [AtlassianPS.JiraAgilePS.Sprint[]] }
                    @{ parameter = "Board"; type = [AtlassianPS.JiraAgilePS.Board] }
                    @{ parameter = "State"; type = [AtlassianPS.JiraAgilePS.SprintState] }
                    @{ parameter = "PageSize"; type = [UInt32] }
                    @{ parameter = "Credential"; type = [System.Management.Automation.PSCredential] }
                ) {
                    $command | Should -HaveParameter $parameter -Type $type
                }
            }

            Context "Default Values" {
                It "parameter '<parameter>' has a default value of '<defaultValue>'" -TestCases @(
                    @{ parameter = "Credential"; defaultValue = "[System.Management.Automation.PSCredential]::Empty" }
                ) {
                    $command | Should -HaveParameter $parameter -DefaultValue $defaultValue
                }
            }
        }

        Describe "Behavior" {
            It "requests all sprints for a board" {
                Mock Invoke-JiraMethod -ModuleName JiraAgilePS {
                    [pscustomobject]@{
                        Id            = 13
                        Name          = "Sprint 13"
                        State         = "active"
                        startDate     = "2026-01-01T00:00:00.000Z"
                        endDate       = "2026-01-14T00:00:00.000Z"
                        completeDate  = "2026-01-13T00:00:00.000Z"
                        OriginBoardId = 4
                        Goal          = "Deliver"
                        Self          = "$jiraServer/rest/agile/1.0/sprint/13"
                    }
                }
                $board = [AtlassianPS.JiraAgilePS.Board]::new(4)

                $result = Get-JiraAgileSprint -Board $board -State active

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq "GET" -and
                    $Uri -eq "$jiraServer/rest/agile/1.0/board/4/sprint" -and
                    $Paging
                }
                $result.Id | Should -Be 13
                $result.Name | Should -Be "Sprint 13"
            }

            It "requests sprint details by sprint id" {
                Mock Invoke-JiraMethod -ModuleName JiraAgilePS {
                    [pscustomobject]@{
                        Id            = 21
                        Name          = "Sprint 21"
                        State         = "future"
                        startDate     = "2026-02-01T00:00:00.000Z"
                        endDate       = "2026-02-14T00:00:00.000Z"
                        completeDate  = $null
                        OriginBoardId = 4
                        Goal          = "Prepare"
                        Self          = "$jiraServer/rest/agile/1.0/sprint/21"
                    }
                }
                $sprint = [AtlassianPS.JiraAgilePS.Sprint]::new(21)

                $result = Get-JiraAgileSprint -Sprint $sprint

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq "GET" -and
                    $Uri -eq "$jiraServer/rest/agile/1.0/sprint/21" -and
                    (-not $Paging)
                }
                $result.Id | Should -Be 21
                $result.Name | Should -Be "Sprint 21"
            }
        }
    }
}
