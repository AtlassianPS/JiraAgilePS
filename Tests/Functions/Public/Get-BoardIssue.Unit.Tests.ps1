#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraAgilePS {
    Describe "Get-JiraAgileBoardIssue" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            $script:jiraServer = "https://jira.example.com"

            Mock Get-JiraConfigServer -ModuleName JiraAgilePS {
                $jiraServer
            }
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name "Get-JiraAgileBoardIssue"
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
            It "requests board issues and converts response issues" {
                Mock Invoke-JiraMethod -ModuleName JiraAgilePS {
                    [pscustomobject]@{
                        issues = @(
                            [pscustomobject]@{ id = "1001"; key = "AG-1" },
                            [pscustomobject]@{ id = "1002"; key = "AG-2" }
                        )
                    }
                }
                $board = [AtlassianPS.JiraAgilePS.Board]::new(7)

                $result = Get-JiraAgileBoardIssue -Board $board

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq "GET" -and
                    $Uri -eq "$jiraServer/rest/agile/1.0/board/7/issue" -and
                    $Paging
                }

                @($result).Count | Should -Be 2
                $result[0].Key | Should -Be "AG-1"
                $result[0].PSObject.TypeNames[0] | Should -Be "AtlassianPS.JiraAgilePS.Issue"
            }
        }
    }
}

