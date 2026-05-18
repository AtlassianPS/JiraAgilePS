#requires -modules Pester

$modulePath = Join-Path $PSScriptRoot "../../JiraAgilePS"
Remove-Module "JiraAgilePS" -ErrorAction SilentlyContinue
Import-Module $modulePath -Force -ErrorAction Stop

Describe "Add-JiraAgileIssueToSprint" -Tag Unit {
    BeforeEach {
        $script:lastInvokeParams = $null
        Mock Invoke-JiraMethod -ModuleName JiraAgilePS {
            param($Uri, $Method, $Body)
            $script:lastInvokeParams = @{
                Uri    = $Uri
                Method = $Method
                Body   = $Body
            }
        }

        Mock Get-Sprint -ModuleName JiraAgilePS {
            [AtlassianPS.JiraAgilePS.Sprint]@{
                Id   = 99
                Self = [Uri]"https://jira.example.com/rest/agile/1.0/sprint/99"
            }
        }
    }

    It "posts issue keys to the sprint issue endpoint" {
        $sprint = [AtlassianPS.JiraAgilePS.Sprint]::new(99)
        $sprint.Self = [Uri]"https://jira.example.com/rest/agile/1.0/sprint/99"
        $issues = @(
            [pscustomobject]@{ Key = "AG-1" }
            [pscustomobject]@{ Key = "AG-2" }
        )

        Add-JiraAgileIssueToSprint -Issue $issues -Sprint $sprint

        Assert-MockCalled Invoke-JiraMethod -ModuleName JiraAgilePS -Times 1 -Exactly -Scope It
        $script:lastInvokeParams.Method | Should -Be "POST"
        $script:lastInvokeParams.Uri | Should -Be "https://jira.example.com/rest/agile/1.0/sprint/99/issue"
        ($script:lastInvokeParams.Body | ConvertFrom-Json).issues | Should -Be @("AG-1", "AG-2")
    }

    It "resolves sprint details when Self is not provided" {
        $sprintWithoutSelf = [AtlassianPS.JiraAgilePS.Sprint]::new(99)
        $issues = @([pscustomobject]@{ Key = "AG-1" })

        Add-JiraAgileIssueToSprint -Issue $issues -Sprint $sprintWithoutSelf

        Assert-MockCalled Get-Sprint -ModuleName JiraAgilePS -Times 1 -Exactly -Scope It
        Assert-MockCalled Invoke-JiraMethod -ModuleName JiraAgilePS -Times 1 -Exactly -Scope It
    }
}
