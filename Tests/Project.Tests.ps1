#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
    $script:moduleRoot = Resolve-ProjectRoot
}

Describe "General project validation" -Tag Unit {
    BeforeDiscovery {
        $script:module = Get-Module 'JiraAgilePS'
        $modulePrefix = $script:module.Prefix

        $script:testFiles = Get-ChildItem $PSScriptRoot -Include "*.Tests.ps1" -Recurse

        $script:publicFunctionFiles = (Get-ChildItem "$moduleRoot/JiraAgilePS/Public/*.ps1").BaseName
        $script:privateFunctionFiles = (Get-ChildItem "$moduleRoot/JiraAgilePS/Private/*.ps1").BaseName

        $script:exportedFunctionNames = @($script:module.ExportedFunctions.Keys)
        $script:normalizedExportedFunctionNames = @(
            foreach ($name in $script:exportedFunctionNames) {
                if ([string]::IsNullOrWhiteSpace($modulePrefix)) {
                    $name
                    continue
                }

                if ($name -notmatch '^(?<verb>[^-]+)-(?<noun>.+)$') {
                    $name
                    continue
                }

                $verb = $Matches.verb
                $noun = $Matches.noun

                if ($noun.StartsWith($modulePrefix, [System.StringComparison]::Ordinal)) {
                    "$verb-$($noun.Substring($modulePrefix.Length))"
                }
                else {
                    $name
                }
            }
        )
    }

    Describe "Public functions" {
        Context "Function <_>" -ForEach $publicFunctionFiles {
            BeforeAll {
                $script:functionName = $_
            }
            It "has a test file" {
                $expectedTestFile = "$functionName.Unit.Tests.ps1"
                $testFiles.Name | Should -Contain $expectedTestFile
            }

            It "is exported" {
                $normalizedExportedFunctionNames | Should -Contain $functionName
            }
        }
    }

    Describe "Private functions" {
        It "has private functions" {
            $privateFunctionFiles.Count | Should -BeGreaterThan 0
        }

        Context "Function <_>" -ForEach $privateFunctionFiles {
            BeforeAll {
                $script:functionName = $_
            }

            It "is loaded in the module" {
                $commandInModule = $module.Invoke({ Get-Command -Name $args[0] -ErrorAction SilentlyContinue }, $functionName)

                $commandInModule | Should -Not -BeNullOrEmpty -Because "private function '$functionName' should be loaded"
            }

            It "is not exported" {
                $normalizedExportedFunctionNames | Should -Not -Contain $functionName
            }
        }
    }

    Describe "Project structure" {
        It "only exports functions from the Public folder" {
            foreach ($normalizedExportedFunctionName in $normalizedExportedFunctionNames) {
                $publicFunctionFiles | Should -Contain $normalizedExportedFunctionName -Because "exported function '$normalizedExportedFunctionName' should have a corresponding file in JiraAgilePS/Public/"
            }
        }
    }
}
