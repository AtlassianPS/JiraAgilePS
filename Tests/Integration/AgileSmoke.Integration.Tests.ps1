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

        It "can call the Agile board endpoint" {
            { $script:boards = @(Get-JiraAgileBoard -PageSize 1 -ErrorAction Stop) } | Should -Not -Throw

            if ($script:boards.Count -gt 0) {
                $script:boards[0].PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraAgilePS.Board'
                $script:boards[0].Id | Should -Not -BeNullOrEmpty
            }
        }
    }
}
