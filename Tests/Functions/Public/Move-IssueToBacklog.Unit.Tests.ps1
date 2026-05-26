#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

BeforeAll {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

Describe "Move-JiraAgileIssueToBacklog" -Tag 'Unit' {
    BeforeAll {
        $script:jiraServer = "https://jira.example.com"

        Mock Get-JiraConfigServer -ModuleName JiraAgilePS {
            $jiraServer
        }
    }

    BeforeEach {
        $script:postedBodies = [System.Collections.Generic.List[string]]::new()

        Mock Invoke-JiraMethod -ModuleName JiraAgilePS {
            param($Body)
            $null = $script:postedBodies.Add($Body)
        }
    }

    Describe "Signature" {
        BeforeAll {
            $script:command = Get-Command -Name "Move-JiraAgileIssueToBacklog"
        }

        Context "Parameter Types" {
            It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                @{ parameter = "Issue"; type = [Object] }
                @{ parameter = "Credential"; type = [System.Management.Automation.PSCredential] }
            ) {
                $command | Should -HaveParameter $parameter -Type $type
            }
        }

        Context "Default Values" {
            It "parameter '<parameter>' has a default value of '<defaultValue>'" -TestCases @(
                @{ parameter = "Credential"; defaultValue = "[System.Management.Automation.PSCredential]::Empty" }
            ) {
                $command | Should -HaveParameter $parameter -DefaultValue $defaultValue
            }
        }

        Context "Mandatory Parameters" {
            It "parameter '<parameter>' is mandatory" -TestCases @(
                @{ parameter = "Issue" }
            ) {
                $command | Should -HaveParameter $parameter -Mandatory
            }
        }
    }

    Describe "Behavior" {
        It "posts issue keys to the backlog endpoint" {
            $issues = @(
                [pscustomobject]@{ Key = "AG-1" }
                [pscustomobject]@{ Key = "AG-2" }
            )

            { Move-JiraAgileIssueToBacklog -Issue $issues -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                $Method -eq "POST" -and
                $Uri -eq "$jiraServer/rest/agile/1.0/backlog/issue" -and
                (($Body | ConvertFrom-Json).issues -join ",") -eq "AG-1,AG-2"
            }
        }

        It "accepts string issue identifiers" {
            { Move-JiraAgileIssueToBacklog -Issue @("AG-3", "10004") -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                (($Body | ConvertFrom-Json).issues -join ",") -eq "AG-3,10004"
            }
        }

        It "sends backlog payloads in pages of 50 issue keys" {
            $issues = @(1..55 | ForEach-Object { [pscustomobject]@{ Key = "AG-$_" } })

            { Move-JiraAgileIssueToBacklog -Issue $issues -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 2 -Scope It

            $firstBodyIssues = ($script:postedBodies[0] | ConvertFrom-Json).issues
            $secondBodyIssues = ($script:postedBodies[1] | ConvertFrom-Json).issues

            @($firstBodyIssues).Count | Should -Be 50
            $firstBodyIssues[0] | Should -Be "AG-1"
            $firstBodyIssues[-1] | Should -Be "AG-50"

            @($secondBodyIssues).Count | Should -Be 5
            $secondBodyIssues[0] | Should -Be "AG-51"
            $secondBodyIssues[-1] | Should -Be "AG-55"
        }

        It "does not invoke Jira when WhatIf is used" {
            Move-JiraAgileIssueToBacklog -Issue "AG-1" -WhatIf

            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 0 -Scope It
        }
    }
}
