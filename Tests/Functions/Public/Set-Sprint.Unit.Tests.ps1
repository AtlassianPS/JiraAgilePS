#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

BeforeAll {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

Describe "Set-JiraAgileSprint" -Tag 'Unit' {
    BeforeAll {
        $script:jiraServer = "https://jira.example.com"

        Mock Get-JiraConfigServer -ModuleName JiraAgilePS {
            $jiraServer
        }
    }

    BeforeEach {
        Mock Get-Sprint -ModuleName JiraAgilePS {
            [AtlassianPS.JiraAgilePS.Sprint]@{
                Id            = 21
                Name          = 'Sprint 21'
                State         = [AtlassianPS.JiraAgilePS.SprintState]::future
                StartDate     = [DateTime]'2026-06-01T00:00:00Z'
                EndDate       = [DateTime]'2026-06-14T00:00:00Z'
                OriginBoardId = 9
                Goal          = 'Old goal'
                Self          = [Uri]"$jiraServer/rest/agile/1.0/sprint/21"
            }
        }

        Mock Invoke-JiraMethod -ModuleName JiraAgilePS {
            [pscustomobject]@{
                id            = 21
                name          = 'Updated Sprint'
                state         = 'active'
                startDate     = '2026-06-01T00:00:00.000Z'
                endDate       = '2026-06-14T00:00:00.000Z'
                completeDate  = $null
                originBoardId = 9
                goal          = 'Updated goal'
                self          = "$jiraServer/rest/agile/1.0/sprint/21"
            }
        }
    }

    Describe "Signature" {
        BeforeAll {
            $script:command = Get-Command -Name "Set-JiraAgileSprint"
        }

        Context "Parameter Types" {
            It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                @{ parameter = "Sprint"; type = [AtlassianPS.JiraAgilePS.Sprint[]] }
                @{ parameter = "Name"; type = [string] }
                @{ parameter = "State"; type = [AtlassianPS.JiraAgilePS.SprintState] }
                @{ parameter = "StartDate"; type = [DateTime] }
                @{ parameter = "EndDate"; type = [DateTime] }
                @{ parameter = "Goal"; type = [string] }
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
        It "gets current sprint details, puts an update payload, and returns a typed sprint" {
            $sprint = [AtlassianPS.JiraAgilePS.Sprint]::new(21)

            $result = Set-JiraAgileSprint -Sprint $sprint -Name 'Updated Sprint' -State active -Goal 'Updated goal' -Confirm:$false

            Should -Invoke -CommandName Get-Sprint -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                $payload = $Body | ConvertFrom-Json
                $Method -eq "PUT" -and
                $Uri -eq "$jiraServer/rest/agile/1.0/sprint/21" -and
                $payload.name -eq 'Updated Sprint' -and
                $payload.state -eq 'active' -and
                $payload.goal -eq 'Updated goal' -and
                $payload.originBoardId -eq 9
            }
            $result | Should -BeOfType ([AtlassianPS.JiraAgilePS.Sprint])
            $result.Name | Should -Be 'Updated Sprint'
        }

        It "throws when Sprint has no numeric id" {
            $sprint = [AtlassianPS.JiraAgilePS.Sprint]::new("sprint-name")

            { Set-JiraAgileSprint -Sprint $sprint -Name 'Updated Sprint' -Confirm:$false } |
                Should -Throw "*Sprint input must contain a non-zero Id.*"
        }

        It "does not invoke the update when WhatIf is used" {
            $sprint = [AtlassianPS.JiraAgilePS.Sprint]::new(21)

            Set-JiraAgileSprint -Sprint $sprint -Name 'Updated Sprint' -WhatIf

            Should -Invoke -CommandName Get-Sprint -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 0 -Scope It
        }
    }
}
