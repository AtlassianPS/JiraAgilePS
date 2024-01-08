#requires -modules Pester
#requires -modules PSScriptAnalyzer

BeforeDiscovery {
    $modulePath = "$PSScriptRoot/../JiraAgilePS"
    Import-Module $modulePath

    $psFiles = Get-ChildItem $modulePath -Include *.ps1, *.psm1 -Recurse
}
BeforeAll {
    $moduleRoot, $relativePath = "$PSScriptRoot/.."
    if ($env:BHBuildOutput) { $relativePath = $env:BHBuildOutput }
    Remove-Module "JiraAgilePS" -ErrorAction SilentlyContinue
    Import-Module "$relativePath/JiraAgilePS" -Force
}
AfterAll {
    Remove-Module JiraAgilePS -ErrorAction SilentlyContinue
}

Describe "PSScriptAnalyzer Tests" -Tag Unit {

    BeforeAll {
        $module = Get-Module "JiraAgilePS"
        $modulePath = (Get-Module "JiraAgilePS").Path -replace "JiraAgilePS.psm1", ""
        if ($env:BHBuildOutput) { $settingsFile = "$moduleRoot/PSScriptAnalyzerSettings.psd1" }
        else { $settingsFile = "$moduleRoot/PSScriptAnalyzerSettings.dev.psd1" }

        $Params = @{
            Path          = $modulePath
            Settings      = $settingsFile
            Recurse       = $true
            Verbose       = $false
            ErrorVariable = 'ErrorVariable'
            ErrorAction   = 'SilentlyContinue'
        }
        $ScriptWarnings = Invoke-ScriptAnalyzer @Params
    }

    Describe "<psFileName>" -ForEach $psFiles {

        BeforeAll {
            $psFile = $_
            $psFileName = $psFile.BaseName
        }

        It "passes all rules" {
            $BadLines = $ScriptWarnings | Where-Object { $_.ScriptPath -like $psFile.FullName }
            $BadLines | Should -Be $null
        }

        It "has no parse errors" {
            $Exceptions = $null

            if ($ErrorVariable) {
                $Exceptions = $ErrorVariable.Exception.Message |
                Where-Object { $_ -match [regex]::Escape($psFile.FullName) }
            }

            foreach ($Exception in $Exceptions) {
                $Exception | Should -BeNullOrEmpty
            }
        }
    }
}
