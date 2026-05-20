#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraAgilePS {
    Describe "Get-JiraAgileSprintIssue" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            $script:jiraServer = "https://jira.example.com"

            Mock Get-JiraConfigServer -ModuleName JiraAgilePS {
                $jiraServer
            }
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name "Get-JiraAgileSprintIssue"
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = "Board"; type = [AtlassianPS.JiraAgilePS.Board] }
                    @{ parameter = "Sprint"; type = [AtlassianPS.JiraAgilePS.Sprint[]] }
                    @{ parameter = "PageSize"; type = [UInt32] }
                    @{ parameter = "Credential"; type = [System.Management.Automation.PSCredential] }
                ) {
                    $command | Should -HaveParameter $parameter -Type $type
                }
            }
        }

        Describe "Behavior" {
            It "requests sprint issues for each sprint id" {
                Mock Invoke-JiraMethod -ModuleName JiraAgilePS {
                    param($Uri)
                    $sprintId = [int]($Uri -replace "^.*/sprint/(\d+)/issue$", '$1')

                    [pscustomobject]@{
                        issues = @(
                            [pscustomobject]@{ id = "$sprintId"; key = "AG-$sprintId" }
                        )
                    }
                }
                $board = [AtlassianPS.JiraAgilePS.Board]::new(4)
                $sprintA = [AtlassianPS.JiraAgilePS.Sprint]::new(21)
                $sprintB = [AtlassianPS.JiraAgilePS.Sprint]::new(22)

                $result = Get-JiraAgileSprintIssue -Board $board -Sprint @($sprintA, $sprintB)

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 2 -Scope It
                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq "GET" -and
                    $Uri -eq "$jiraServer/rest/agile/1.0/board/4/sprint/21/issue" -and
                    $Paging
                }
                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq "GET" -and
                    $Uri -eq "$jiraServer/rest/agile/1.0/board/4/sprint/22/issue" -and
                    $Paging
                }

                @($result).Count | Should -Be 2
                (@($result | Select-Object -ExpandProperty Key) -join ",") | Should -Be "AG-21,AG-22"
                $result[0].PSObject.TypeNames[0] | Should -Be "AtlassianPS.JiraAgilePS.Issue"
            }
        }
    }
}

