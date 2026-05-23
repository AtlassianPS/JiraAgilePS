#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraAgilePS {
    Describe "Get-AgilePageItem" -Tag 'Unit' {
        Describe "Behavior" {
            It "expands issues from a paged response" {
                $response = [pscustomobject]@{
                    issues = @(
                        [pscustomobject]@{ key = 'DEL-1' }
                        [pscustomobject]@{ key = 'DEL-2' }
                    )
                }

                $result = @($response | Get-AgilePageItem)

                $result.Key | Should -Be @('DEL-1', 'DEL-2')
            }

            It "expands values from a paged response" {
                $response = [pscustomobject]@{
                    values = @(
                        [pscustomobject]@{ id = 1 }
                        [pscustomobject]@{ id = 2 }
                    )
                }

                $result = @($response | Get-AgilePageItem)

                $result.Id | Should -Be @(1, 2)
            }

            It "returns input objects without a known page property" {
                $inputObject = [pscustomobject]@{ name = 'plain object' }

                $result = $inputObject | Get-AgilePageItem

                $result.Name | Should -Be 'plain object'
            }

            It "ignores null input" {
                $result = $null | Get-AgilePageItem

                $result | Should -BeNullOrEmpty
            }
        }
    }
}
