#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraAgilePS {
    Describe "Get-JiraAgileEpicIssue" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            $script:jiraServer = "https://jira.example.com"

            Mock Get-JiraConfigServer -ModuleName JiraAgilePS {
                $jiraServer
            }
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name "Get-JiraAgileEpicIssue"
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = "Epic"; type = [AtlassianPS.JiraAgilePS.Epic[]] }
                    @{ parameter = "Board"; type = [AtlassianPS.JiraAgilePS.Board] }
                    @{ parameter = "WithoutEpic"; type = [System.Management.Automation.SwitchParameter] }
                    @{ parameter = "PageSize"; type = [UInt32] }
                    @{ parameter = "Credential"; type = [System.Management.Automation.PSCredential] }
                ) {
                    $command | Should -HaveParameter $parameter -Type $type
                }
            }
        }

        Describe "Behavior" {
            It "requests epic issues from the epic endpoint" {
                Mock Invoke-JiraMethod -ModuleName JiraAgilePS {
                    [pscustomobject]@{
                        issues = @(
                            [pscustomobject]@{ id = "3001"; key = "AG-301" }
                        )
                    }
                }
                $epic = [AtlassianPS.JiraAgilePS.Epic]::new(55)

                $result = Get-JiraAgileEpicIssue -Epic $epic

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq "GET" -and
                    $Uri -eq "$jiraServer/rest/agile/1.0/epic/55/issue" -and
                    $Paging
                }

                @($result).Count | Should -Be 1
                $result[0].Key | Should -Be "AG-301"
                $result[0].PSObject.TypeNames[0] | Should -Be "AtlassianPS.JiraAgilePS.Issue"
            }

            It "requests board-scoped epic issues when board and epic are provided" {
                Mock Invoke-JiraMethod -ModuleName JiraAgilePS {
                    [pscustomobject]@{
                        issues = @([pscustomobject]@{ id = "3002"; key = "AG-302" })
                    }
                }
                $board = [AtlassianPS.JiraAgilePS.Board]::new(8)
                $epic = [AtlassianPS.JiraAgilePS.Epic]::new(66)

                $null = Get-JiraAgileEpicIssue -Board $board -Epic $epic

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq "GET" -and
                    $Uri -eq "$jiraServer/rest/agile/1.0/board/8/epic/66/issue" -and
                    $Paging
                }
            }

            It "requests board-scoped issues without epic when WithoutEpic is used" {
                Mock Invoke-JiraMethod -ModuleName JiraAgilePS {
                    [pscustomobject]@{
                        issues = @([pscustomobject]@{ id = "3003"; key = "AG-303" })
                    }
                }
                $board = [AtlassianPS.JiraAgilePS.Board]::new(8)

                $null = Get-JiraAgileEpicIssue -Board $board -WithoutEpic

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq "GET" -and
                    $Uri -eq "$jiraServer/rest/agile/1.0/board/8/epic/none/issue" -and
                    $Paging
                }
            }
        }
    }
}

