#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraAgilePS {
    Describe "Get-JiraAgileBoardEpic" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            $script:jiraServer = "https://jira.example.com"

            Mock Get-JiraConfigServer -ModuleName JiraAgilePS {
                $jiraServer
            }
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name "Get-JiraAgileBoardEpic"
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = "Board"; type = [AtlassianPS.JiraAgilePS.Board] }
                    @{ parameter = "PageSize"; type = [UInt32] }
                    @{ parameter = "Credential"; type = [System.Management.Automation.PSCredential] }
                ) {
                    $command | Should -HaveParameter $parameter -Type $type
                }
            }
        }

        Describe "Behavior" {
            It "requests board epics and converts response values to Epic objects" {
                Mock Invoke-JiraMethod -ModuleName JiraAgilePS {
                    [pscustomobject]@{
                        values = @(
                            [pscustomobject]@{ id = 31; key = "EPIC-31"; name = "Epic 31"; done = $false; self = "$jiraServer/rest/agile/1.0/epic/31" },
                            [pscustomobject]@{ id = 32; key = "EPIC-32"; name = "Epic 32"; done = $true; self = "$jiraServer/rest/agile/1.0/epic/32" }
                        )
                    }
                }
                $board = [AtlassianPS.JiraAgilePS.Board]::new(5)

                $result = Get-JiraAgileBoardEpic -Board $board

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq "GET" -and
                    $Uri -eq "$jiraServer/rest/agile/1.0/board/5/epic" -and
                    $Paging
                }

                @($result).Count | Should -Be 2
                $result[0] | Should -BeOfType [AtlassianPS.JiraAgilePS.Epic]
                $result[0].Name | Should -Be "Epic 31"
                $result[1].Done | Should -BeTrue
            }
        }
    }
}

