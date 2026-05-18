#requires -modules Pester

BeforeAll {
    $relativePath = "$PSScriptRoot/../.."
    if ($env:BHBuildOutput) { $relativePath = $env:BHBuildOutput }
    Remove-Module "JiraAgilePS" -ErrorAction SilentlyContinue
    Import-Module "$relativePath/JiraAgilePS" -Force
}

AfterAll {
    Remove-Module "JiraAgilePS" -ErrorAction SilentlyContinue
}

Describe "Get-JiraAgileSprint" -Tag Unit {
    BeforeEach {
        Mock Get-JiraConfigServer -ModuleName JiraAgilePS {
            "https://jira.example.com"
        }
    }

    It "requests all sprints for a board" {
        Mock Invoke-JiraMethod -ModuleName JiraAgilePS {
            [pscustomobject]@{
                Id            = 13
                Name          = "Sprint 13"
                State         = "active"
                startDate     = "2026-01-01T00:00:00.000Z"
                endDate       = "2026-01-14T00:00:00.000Z"
                completeDate  = "2026-01-13T00:00:00.000Z"
                OriginBoardId = 4
                Goal          = "Deliver"
                Self          = "https://jira.example.com/rest/agile/1.0/sprint/13"
            }
        }
        $board = [AtlassianPS.JiraAgilePS.Board]::new(4)

        $result = Get-JiraAgileSprint -Board $board -State active

        Assert-MockCalled Invoke-JiraMethod -ModuleName JiraAgilePS -Times 1 -Exactly -Scope It -ParameterFilter {
            $Method -eq "GET" -and $Uri -eq "https://jira.example.com/rest/agile/1.0/board/4/sprint" -and $Paging
        }
        $result.Id | Should -Be 13
        $result.Name | Should -Be "Sprint 13"
    }

    It "requests sprint details by sprint id" {
        Mock Invoke-JiraMethod -ModuleName JiraAgilePS {
            [pscustomobject]@{
                Id            = 21
                Name          = "Sprint 21"
                State         = "future"
                startDate     = "2026-02-01T00:00:00.000Z"
                endDate       = "2026-02-14T00:00:00.000Z"
                completeDate  = $null
                OriginBoardId = 4
                Goal          = "Prepare"
                Self          = "https://jira.example.com/rest/agile/1.0/sprint/21"
            }
        }
        $sprint = [AtlassianPS.JiraAgilePS.Sprint]::new(21)

        $result = Get-JiraAgileSprint -Sprint $sprint

        Assert-MockCalled Invoke-JiraMethod -ModuleName JiraAgilePS -Times 1 -Exactly -Scope It -ParameterFilter {
            $Method -eq "GET" -and $Uri -eq "https://jira.example.com/rest/agile/1.0/sprint/21" -and -not $Paging
        }
        $result.Id | Should -Be 21
        $result.Name | Should -Be "Sprint 21"
    }
}
