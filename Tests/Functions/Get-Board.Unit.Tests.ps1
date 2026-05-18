#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraAgilePS {
    Describe "Get-JiraAgileBoard" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/TestTools.ps1"
            $script:jiraServer = "https://jira.example.com"

            Mock Get-JiraConfigServer -ModuleName JiraAgilePS {
                $jiraServer
            }
        }

        Describe "Behavior" {
            It "requests all boards from the agile board endpoint" {
                Mock Invoke-JiraMethod -ModuleName JiraAgilePS {
                    [pscustomobject]@{
                        Id   = 1
                        Name = "Main board"
                        Type = "scrum"
                        Self = "$jiraServer/rest/agile/1.0/board/1"
                    }
                }

                $result = Get-JiraAgileBoard

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq "GET" -and
                    $Uri -eq "$jiraServer/rest/agile/1.0/board" -and
                    $Paging
                }
                $result.Id | Should -Be 1
                $result.Name | Should -Be "Main board"
            }

            It "requests a specific board when BoardId is supplied" {
                Mock Invoke-JiraMethod -ModuleName JiraAgilePS {
                    [pscustomobject]@{
                        Id   = 7
                        Name = "Target board"
                        Type = "kanban"
                        Self = "$jiraServer/rest/agile/1.0/board/7"
                    }
                }

                $result = Get-JiraAgileBoard -BoardId 7

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq "GET" -and
                    $Uri -eq "$jiraServer/rest/agile/1.0/board/7" -and
                    (-not $Paging)
                }
                $result.Id | Should -Be 7
                $result.Name | Should -Be "Target board"
            }
        }
    }
}
