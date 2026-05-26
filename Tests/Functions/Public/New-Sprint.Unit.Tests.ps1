#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

BeforeAll {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

Describe "New-JiraAgileSprint" -Tag 'Unit' {
    BeforeAll {
        $script:jiraServer = "https://jira.example.com"

        Mock Get-JiraConfigServer -ModuleName JiraAgilePS {
            $jiraServer
        }
    }

    BeforeEach {
        Mock Invoke-JiraMethod -ModuleName JiraAgilePS {
            [pscustomobject]@{
                id            = 101
                name          = 'Sprint 101'
                state         = 'future'
                startDate     = '2026-06-01T00:00:00.000Z'
                endDate       = '2026-06-14T00:00:00.000Z'
                completeDate  = $null
                originBoardId = 9
                goal          = 'Ship write cmdlets'
                self          = "$jiraServer/rest/agile/1.0/sprint/101"
            }
        }
    }

    Describe "Signature" {
        BeforeAll {
            $script:command = Get-Command -Name "New-JiraAgileSprint"
        }

        Context "Parameter Types" {
            It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                @{ parameter = "Name"; type = [string] }
                @{ parameter = "Board"; type = [AtlassianPS.JiraAgilePS.Board] }
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
                @{ parameter = "Name" }
                @{ parameter = "Board" }
            ) {
                $command | Should -HaveParameter $parameter -Mandatory
            }
        }
    }

    Describe "Behavior" {
        It "posts a sprint create payload and returns a typed sprint" {
            $board = [AtlassianPS.JiraAgilePS.Board]::new(9)
            $startDate = [DateTime]'2026-06-01T00:00:00Z'
            $endDate = [DateTime]'2026-06-14T00:00:00Z'

            $result = New-JiraAgileSprint -Board $board -Name 'Sprint 101' -StartDate $startDate -EndDate $endDate -Goal 'Ship write cmdlets' -Confirm:$false

            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 1 -Scope It -ParameterFilter {
                $payload = $Body | ConvertFrom-Json
                $Method -eq "POST" -and
                $Uri -eq "$jiraServer/rest/agile/1.0/sprint" -and
                $payload.name -eq 'Sprint 101' -and
                $payload.originBoardId -eq 9 -and
                $payload.goal -eq 'Ship write cmdlets' -and
                $Body -match '"startDate"\s*:\s*"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}[+-]\d{2}:\d{2}"' -and
                $Body -match '"endDate"\s*:\s*"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}[+-]\d{2}:\d{2}"'
            }
            $result | Should -BeOfType ([AtlassianPS.JiraAgilePS.Sprint])
            $result.Id | Should -Be 101
        }

        It "throws when Board has no numeric id" {
            $board = [AtlassianPS.JiraAgilePS.Board]::new("team-board")

            { New-JiraAgileSprint -Board $board -Name 'Sprint 101' -Confirm:$false } |
                Should -Throw "*Board input must contain a non-zero Id.*"
        }

        It "does not invoke Jira when WhatIf is used" {
            $board = [AtlassianPS.JiraAgilePS.Board]::new(9)

            New-JiraAgileSprint -Board $board -Name 'Sprint 101' -WhatIf

            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraAgilePS -Exactly -Times 0 -Scope It
        }
    }
}
