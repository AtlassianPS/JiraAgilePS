#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraAgilePS {
    Describe "Get-JiraAgileIssue" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            $script:jiraServer = "https://jira.example.com"

            Mock Get-JiraConfigServer -ModuleName JiraAgilePS {
                $jiraServer
            }
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name "Get-JiraAgileIssue"
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = "Board"; type = [AtlassianPS.JiraAgilePS.Board] }
                    @{ parameter = "Backlog"; type = [System.Management.Automation.SwitchParameter] }
                    @{ parameter = "Sprint"; type = [AtlassianPS.JiraAgilePS.Sprint[]] }
                    @{ parameter = "PageSize"; type = [UInt32] }
                    @{ parameter = "Credential"; type = [System.Management.Automation.PSCredential] }
                ) {
                    $command | Should -HaveParameter $parameter -Type $type
                }
            }
        }

        Describe "Behavior" {
            BeforeEach {
                Mock Invoke-JiraMethod -ModuleName JiraAgilePS {
                    param($Uri)
                    [pscustomobject]@{
                        issues = @(
                            [pscustomobject]@{
                                id  = "1000"
                                key = "AG-1000"
                                uri = $Uri
                            }
                        )
                    }
                }
            }

            It "uses board issue endpoint by default" {
                $board = [AtlassianPS.JiraAgilePS.Board]::new(7)

                $result = Get-JiraAgileIssue -Board $board

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq "GET" -and
                    $Uri -eq "$jiraServer/rest/agile/1.0/board/7/issue" -and
                    $Paging
                }
                $result[0].Key | Should -Be "AG-1000"
            }

            It "uses backlog endpoint when Backlog switch is specified" {
                $board = [AtlassianPS.JiraAgilePS.Board]::new(8)

                $result = Get-JiraAgileIssue -Board $board -Backlog

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq "GET" -and
                    $Uri -eq "$jiraServer/rest/agile/1.0/board/8/backlog" -and
                    $Paging
                }
                $result[0].Key | Should -Be "AG-1000"
            }

            It "uses sprint endpoint for each sprint in sprint parameter set" {
                $board = [AtlassianPS.JiraAgilePS.Board]::new(9)
                $sprintA = [AtlassianPS.JiraAgilePS.Sprint]::new(21)
                $sprintB = [AtlassianPS.JiraAgilePS.Sprint]::new(22)

                $result = Get-JiraAgileIssue -Board $board -Sprint @($sprintA, $sprintB)

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 2 -Scope It
                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq "GET" -and
                    $Uri -eq "$jiraServer/rest/agile/1.0/board/9/sprint/21/issue" -and
                    $Paging
                }
                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq "GET" -and
                    $Uri -eq "$jiraServer/rest/agile/1.0/board/9/sprint/22/issue" -and
                    $Paging
                }
                @($result).Count | Should -Be 2
            }
        }
    }
}

