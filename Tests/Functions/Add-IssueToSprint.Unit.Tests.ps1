#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraAgilePS {
    Describe "Add-JiraAgileIssueToSprint" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/TestTools.ps1"
            $script:sprintUri = "https://jira.example.com/rest/agile/1.0/sprint/99"
        }

        BeforeEach {
            Mock Get-Sprint -ModuleName JiraAgilePS {
                [AtlassianPS.JiraAgilePS.Sprint]@{
                    Id   = 99
                    Self = [Uri]$sprintUri
                }
            }

            Mock Invoke-JiraMethod -ModuleName JiraAgilePS {
                param($Uri, $Method, $Body)
            }
        }

        Describe "Behavior" {
            It "posts issue keys to the sprint issue endpoint" {
                $sprint = [AtlassianPS.JiraAgilePS.Sprint]::new(99)
                $sprint.Self = [Uri]$sprintUri
                $issues = @(
                    [pscustomobject]@{ Key = "AG-1" }
                    [pscustomobject]@{ Key = "AG-2" }
                )

                { Add-JiraAgileIssueToSprint -Issue $issues -Sprint $sprint } | Should -Not -Throw

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq "POST" -and
                    $Uri -eq "$sprintUri/issue" -and
                    (($Body | ConvertFrom-Json).issues -join ",") -eq "AG-1,AG-2"
                }
            }

            It "resolves sprint details when Self is not provided" {
                $sprintWithoutSelf = [AtlassianPS.JiraAgilePS.Sprint]::new(99)
                $issues = @([pscustomobject]@{ Key = "AG-1" })

                { Add-JiraAgileIssueToSprint -Issue $issues -Sprint $sprintWithoutSelf } | Should -Not -Throw

                Should -Invoke -CommandName Get-Sprint -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It
            }
        }
    }
}
