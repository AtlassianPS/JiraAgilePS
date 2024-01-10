#requires -modules Pester

BeforeDiscovery {
    $modulePath = "$PSScriptRoot/../JiraAgilePS"
    Import-Module $modulePath

    $publicFunctions = Get-ChildItem "$modulePath/Public/*.ps1" | Select-Object -Expand BaseName
    $privateFunctions = Get-ChildItem "$modulePath/Private/*.ps1" | Select-Object -Expand BaseName
}
BeforeAll {
    $relativePath = "$PSScriptRoot/.."
    # if ($env:BHBuildOutput) { $relativePath = $env:BHBuildOutput } ## This test always needs root of the porject
    Remove-Module "JiraAgilePS" -ErrorAction SilentlyContinue
    Import-Module "$relativePath/JiraAgilePS" -Force
}
AfterAll {
    Remove-Module "JiraAgilePS" -ErrorAction SilentlyContinue
}

Describe "General project validation" -Tag Unit {

    BeforeAll {
        $module = Get-Module "JiraAgilePS"
        $modulePath = (Get-Module "JiraAgilePS").Path -replace "JiraAgilePS.psm1", ""
        $testFiles = Get-ChildItem $PSScriptRoot -Include "*.Tests.ps1" -Recurse
        $publicFunctions = Get-ChildItem "$modulePath/Public/*.ps1" | Select-Object -Expand BaseName
    }

    Describe "Public functions" {
        Describe "<_>" -ForEach @($publicFunctions) {

            It "has a test file" {
                $functionName = $_
                $expectedTestFile = "$functionName.Unit.Tests.ps1"

                $testFiles.Name | Should -Contain $expectedTestFile
            }

            It "is exported" {
                $functionName = $_
                $expectedFunctionName = $functionName -replace "\-", "-$($module.Prefix)"

                $module.ExportedCommands.keys | Should -Contain $expectedFunctionName
            }
        }
    }

    Describe "Private functions" {
        Describe "<_>" -ForEach @($privateFunctions) {
            # TODO:
            # It "has a test file" {
            #     $functionName = $_
            #     $expectedTestFile = "$functionName.Unit.Tests.ps1"

            #     $testFiles.Name | Should -Contain $expectedTestFile
            # }

            It "is not exported" {
                $functionName = $_
                $expectedFunctionName = $functionName -replace "\-", "-$($module.Prefix)"

                $module.ExportedCommands.keys | Should -Not -Contain $expectedFunctionName
            }
        }
    }

    <#
    Describe "Classes" {

        foreach ($class in ([AtlassianPS.ServerData].Assembly.GetTypes() | Where-Object IsClass)) {
            It "has a test file for $class" {
                $expectedTestFile = "$class.Unit.Tests.ps1"
                $testFiles.Name | Should -Contain $expectedTestFile
            }
        }
    }

    Describe "Enumeration" {

        foreach ($enum in ([AtlassianPS.ServerData].Assembly.GetTypes() | Where-Object IsEnum)) {
            It "has a test file for $enum" {
                $expectedTestFile = "$enum.Unit.Tests.ps1"
                $testFiles.Name | Should -Contain $expectedTestFile
            }
        }
    }
#>

    Describe "Project stucture" {

        It "defines <_> as dedicated file in 'JiraAgilePS/Public'" -ForEach (Get-Module "JiraAgilePS").ExportedFunctions.Keys {
            $functionName = $_
            $function = $functionName.Replace((Get-Module -Name JiraAgilePS).Prefix, '')

            $publicFunctions | Should -Contain $function
        }
    }
}
