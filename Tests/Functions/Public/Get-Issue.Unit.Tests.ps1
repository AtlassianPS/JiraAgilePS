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
                    @{ parameter = "Epic"; type = [AtlassianPS.JiraAgilePS.Epic[]] }
                    @{ parameter = "WithoutEpic"; type = [System.Management.Automation.SwitchParameter] }
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

            It "accepts numeric board ids via transformer" {
                $null = Get-JiraAgileIssue -Board 7

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq "GET" -and
                    $Uri -eq "$jiraServer/rest/agile/1.0/board/7/issue" -and
                    $Paging
                }
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

            It "accepts numeric sprint ids via transformer" {
                $null = Get-JiraAgileIssue -Board 9 -Sprint 21

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq "GET" -and
                    $Uri -eq "$jiraServer/rest/agile/1.0/board/9/sprint/21/issue" -and
                    $Paging
                }
            }

            It "uses epic endpoint when Epic is supplied without Board" {
                $epicA = [AtlassianPS.JiraAgilePS.Epic]::new(55)
                $epicB = [AtlassianPS.JiraAgilePS.Epic]::new(56)

                $result = Get-JiraAgileIssue -Epic @($epicA, $epicB)

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 2 -Scope It
                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq "GET" -and
                    $Uri -eq "$jiraServer/rest/agile/1.0/epic/55/issue" -and
                    $Paging
                }
                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq "GET" -and
                    $Uri -eq "$jiraServer/rest/agile/1.0/epic/56/issue" -and
                    $Paging
                }
                @($result).Count | Should -Be 2
            }

            It "accepts numeric epic ids via transformer" {
                $null = Get-JiraAgileIssue -Epic 55

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq "GET" -and
                    $Uri -eq "$jiraServer/rest/agile/1.0/epic/55/issue" -and
                    $Paging
                }
            }

            It "uses board epic endpoint when Board and Epic are supplied" {
                $board = [AtlassianPS.JiraAgilePS.Board]::new(8)
                $epic = [AtlassianPS.JiraAgilePS.Epic]::new(66)

                $null = Get-JiraAgileIssue -Board $board -Epic $epic

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq "GET" -and
                    $Uri -eq "$jiraServer/rest/agile/1.0/board/8/epic/66/issue" -and
                    $Paging
                }
            }

            It "uses board none endpoint when WithoutEpic is used" {
                $board = [AtlassianPS.JiraAgilePS.Board]::new(8)

                $null = Get-JiraAgileIssue -Board $board -WithoutEpic

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq "GET" -and
                    $Uri -eq "$jiraServer/rest/agile/1.0/board/8/epic/none/issue" -and
                    $Paging
                }
            }

            It "accepts Board from pipeline in backlog parameter set" {
                $board = [AtlassianPS.JiraAgilePS.Board]::new(11)

                $null = $board | Get-JiraAgileIssue -Backlog

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq "GET" -and
                    $Uri -eq "$jiraServer/rest/agile/1.0/board/11/backlog" -and
                    $Paging
                }
            }

            It "forwards paging parameters to Invoke-JiraMethod" {
                $board = [AtlassianPS.JiraAgilePS.Board]::new(13)

                $null = Get-JiraAgileIssue -Board $board -First 2 -Skip 1

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq "GET" -and
                    $Uri -eq "$jiraServer/rest/agile/1.0/board/13/issue" -and
                    $Paging -and
                    $First -eq 2 -and
                    $Skip -eq 1
                }
            }

            It "throws when Board has no numeric id" {
                $board = [AtlassianPS.JiraAgilePS.Board]::new("my-board")

                { Get-JiraAgileIssue -Board $board } |
                    Should -Throw "*Board input must contain a non-zero Id.*"
            }

            It "throws when Sprint has no numeric id" {
                $board = [AtlassianPS.JiraAgilePS.Board]::new(9)
                $sprint = [AtlassianPS.JiraAgilePS.Sprint]::new("my-sprint")

                { Get-JiraAgileIssue -Board $board -Sprint $sprint } |
                    Should -Throw "*Sprint input must contain a non-zero Id.*"
            }

            It "throws when Epic has no numeric id" {
                $epic = [AtlassianPS.JiraAgilePS.Epic]::new("my-epic")

                { Get-JiraAgileIssue -Epic $epic } |
                    Should -Throw "*Epic input must contain a non-zero Id.*"
            }
        }
    }
}
