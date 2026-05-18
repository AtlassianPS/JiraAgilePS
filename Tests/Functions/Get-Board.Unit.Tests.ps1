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

Describe "Get-JiraAgileBoard" -Tag Unit {
    BeforeEach {
        Mock Get-JiraConfigServer -ModuleName JiraAgilePS {
            "https://jira.example.com"
        }
    }

    It "requests all boards from the agile board endpoint" {
        Mock Invoke-JiraMethod -ModuleName JiraAgilePS {
            [pscustomobject]@{
                Id   = 1
                Name = "Main board"
                Type = "scrum"
                Self = "https://jira.example.com/rest/agile/1.0/board/1"
            }
        }

        $result = Get-JiraAgileBoard

        Assert-MockCalled Invoke-JiraMethod -ModuleName JiraAgilePS -Times 1 -Exactly -Scope It -ParameterFilter {
            $Method -eq "GET" -and $Uri -eq "https://jira.example.com/rest/agile/1.0/board" -and $Paging
        }
        $result.Id | Should -Be 1
        $result.Name | Should -Be "Main board"
    }

    It "requests a specific board when BoardId is supplied" {
        Mock Invoke-JiraMethod -ModuleName JiraAgilePS {
            [pscustomobject]@{
                Id   = 7
                Name = "Target board"
                Type = "kanban"
                Self = "https://jira.example.com/rest/agile/1.0/board/7"
            }
        }

        $result = Get-JiraAgileBoard -BoardId 7

        Assert-MockCalled Invoke-JiraMethod -ModuleName JiraAgilePS -Times 1 -Exactly -Scope It -ParameterFilter {
            $Method -eq "GET" -and $Uri -eq "https://jira.example.com/rest/agile/1.0/board/7" -and -not $Paging
        }
        $result.Id | Should -Be 7
        $result.Name | Should -Be "Target board"
    }
}
