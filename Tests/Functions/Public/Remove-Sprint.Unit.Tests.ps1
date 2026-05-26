#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

BeforeAll {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

Describe "Remove-JiraAgileSprint" -Tag 'Unit' {
    BeforeAll {
        $script:jiraServer = "https://jira.example.com"

        Mock Get-JiraConfigServer -ModuleName JiraAgilePS {
            $jiraServer
        }
    }

    BeforeEach {
        Mock Invoke-JiraMethod -ModuleName JiraAgilePS { }
    }

    Describe "Signature" {
        BeforeAll {
            $script:command = Get-Command -Name "Remove-JiraAgileSprint"
        }

        Context "Parameter Types" {
            It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                @{ parameter = "Sprint"; type = [AtlassianPS.JiraAgilePS.Sprint[]] }
                @{ parameter = "Credential"; type = [System.Management.Automation.PSCredential] }
            ) {
                $command | Should -HaveParameter $parameter -Type $type
            }
        }

        Context "Mandatory Parameters" {
            It "parameter '<parameter>' is mandatory" -TestCases @(
                @{ parameter = "Sprint" }
            ) {
                $command | Should -HaveParameter $parameter -Mandatory
            }
        }
    }

    Describe "Behavior" {
        It "deletes each supplied sprint" {
            $sprintA = [AtlassianPS.JiraAgilePS.Sprint]::new(21)
            $sprintB = [AtlassianPS.JiraAgilePS.Sprint]::new(22)

            { Remove-JiraAgileSprint -Sprint @($sprintA, $sprintB) -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                $Method -eq "DELETE" -and $Uri -eq "$jiraServer/rest/agile/1.0/sprint/21"
            }
            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                $Method -eq "DELETE" -and $Uri -eq "$jiraServer/rest/agile/1.0/sprint/22"
            }
        }

        It "throws when Sprint has no numeric id" {
            $sprint = [AtlassianPS.JiraAgilePS.Sprint]::new("sprint-name")

            { Remove-JiraAgileSprint -Sprint $sprint -Confirm:$false } |
                Should -Throw "*Sprint input must contain a non-zero Id.*"
        }

        It "does not invoke Jira when WhatIf is used" {
            $sprint = [AtlassianPS.JiraAgilePS.Sprint]::new(21)

            Remove-JiraAgileSprint -Sprint $sprint -WhatIf

            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 0 -Scope It
        }
    }
}
