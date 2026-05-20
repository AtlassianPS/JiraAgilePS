#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraAgilePS {
    Describe "Get-JiraAgileEpic" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            $script:jiraServer = "https://jira.example.com"

            Mock Get-JiraConfigServer -ModuleName JiraAgilePS {
                $jiraServer
            }
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name "Get-JiraAgileEpic"
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = "Epic"; type = [AtlassianPS.JiraAgilePS.Epic[]] }
                    @{ parameter = "Credential"; type = [System.Management.Automation.PSCredential] }
                ) {
                    $command | Should -HaveParameter $parameter -Type $type
                }
            }
        }

        Describe "Behavior" {
            It "requests each epic id and converts response to Epic objects" {
                Mock Invoke-JiraMethod -ModuleName JiraAgilePS {
                    param($Uri)
                    $epicId = [int]($Uri -replace "^.*/epic/(\d+)$", '$1')

                    [pscustomobject]@{
                        id      = $epicId
                        key     = "EPIC-$epicId"
                        name    = "Epic $epicId"
                        summary = "Summary $epicId"
                        done    = $false
                        self    = "$jiraServer/rest/agile/1.0/epic/$epicId"
                    }
                }
                $epicA = [AtlassianPS.JiraAgilePS.Epic]::new(41)
                $epicB = [AtlassianPS.JiraAgilePS.Epic]::new(42)

                $result = Get-JiraAgileEpic -Epic @($epicA, $epicB)

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 2 -Scope It
                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq "GET" -and
                    $Uri -eq "$jiraServer/rest/agile/1.0/epic/41"
                }
                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq "GET" -and
                    $Uri -eq "$jiraServer/rest/agile/1.0/epic/42"
                }

                @($result).Count | Should -Be 2
                $result[0] | Should -BeOfType [AtlassianPS.JiraAgilePS.Epic]
                (@($result | Select-Object -ExpandProperty Key) -join ",") | Should -Be "EPIC-41,EPIC-42"
            }
        }
    }
}

