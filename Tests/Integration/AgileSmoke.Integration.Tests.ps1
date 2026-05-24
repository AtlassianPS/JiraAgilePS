#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment

    $script:Skip = Skip-IntegrationTest
}

InModuleScope JiraAgilePS {
    Describe "Agile smoke" -Tag 'Integration', 'Smoke', 'Server', 'Cloud' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:env = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $env
        }

        AfterAll {
            Remove-JiraSession -ErrorAction SilentlyContinue
        }

        It "can establish a Jira session" {
            Get-JiraConfigServer | Should -Be $script:env.CloudUrl
            $script:session | Should -Not -BeNullOrEmpty
        }

        It "can call the Agile board endpoint" {
            try {
                $script:boards = @(Get-JiraAgileBoard -PageSize 1 -ErrorAction Stop)
            }
            catch {
                if (-not $script:env.IsCloud -and $_.Exception.Message -match '404') {
                    Set-ItResult -Skipped -Because 'The Dockerized AMPS Jira image exposes Jira Core but not Jira Software Agile REST.'
                    return
                }
                throw
            }

            if ($script:boards.Count -gt 0) {
                $script:boards[0].PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraAgilePS.Board'
                $script:boards[0].Id | Should -Not -BeNullOrEmpty
            }
        }
    }
}
