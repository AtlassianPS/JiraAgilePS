#requires -modules Configuration
#requires -modules Pester

BeforeAll {
    $relativePath = "$PSScriptRoot/.."
    if ($env:BHBuildOutput) { $relativePath = $env:BHBuildOutput }
    Remove-Module "JiraAgilePS" -ErrorAction SilentlyContinue
    Import-Module "$relativePath/JiraAgilePS" -Force
}
AfterAll {
    Remove-Module JiraAgilePS -ErrorAction SilentlyContinue
}

Describe "Validation of build environment" -Tag Unit {

    BeforeAll {
        $module = Get-Module JiraAgilePS
    }

    It "is a build" {
        $module.Name | Should -Be "JiraAgilePs"
    }

    Context "CHANGELOG" {

        BeforeAll {
            $changelogFile = "$relativePath/CHANGELOG.md"
        }

        It "has a changelog file" {
            $changelogFile | Should -Exist
        }

        Context "CHANGELOG content" {

            BeforeAll {
                function Get-FirstVersionFromChangeLog($Path) {
                    foreach ($line in (Get-Content $Path)) {
                        if ($line -match "(?:##|\<h2.*?\>)\s*\[(?<Version>(\d+\.?){1,2})\]") {
                            return $matches.Version
                        }
                    }
                }

                $changelogVersion = Get-FirstVersionFromChangeLog -Path $changelogFile
            }

            It "has a valid version in the changelog" {
                $changelogVersion             | Should -Not -BeNullOrEmpty
                [Version]($changelogVersion)  | Should -BeOfType [Version]
            }

            It "has a version changelog that matches the manifest version" {
                $metadataFile = $module.Path -replace "psm1", "psd1"
                Get-Metadata -Path $metadataFile -PropertyName ModuleVersion | Should -BeLike "$changelogVersion*"
            }
        }
    }
}
