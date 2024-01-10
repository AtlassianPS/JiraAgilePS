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

Describe "General project validation" -Tag Unit {

    BeforeAll {
        $module = Get-Module JiraAgilePS
        $metadataFile = $module.Path -replace "psm1", "psd1"
        Remove-Module JiraAgilePS
    }

    It "passes Test-ModuleManifest" {
        { Test-ModuleManifest -Path $metadataFile -ErrorAction Stop } | Should -Not -Throw
    }

    It "module can import without errors" {
        { Import-Module $metadataFile } | Should -Not -Throw
    }

    It "module exports functions" {
        Import-Module $metadataFile

        (Get-Command -Module "JiraAgilePS" | Measure-Object).Count | Should -BeGreaterThan 0
    }

    It "module uses the correct root module" {
        Get-Metadata -Path $metadataFile -PropertyName RootModule | Should -Be 'JiraAgilePS.psm1'
    }

    It "module uses the correct guid" {
        Get-Metadata -Path $metadataFile -PropertyName Guid | Should -Be '4de7d140-4fb6-4ac3-a187-82dcd762ebe9'
    }

    It "module uses a valid version" {
        [Version](Get-Metadata -Path $metadataFile -PropertyName ModuleVersion) | Should -Not -BeNullOrEmpty
        [Version](Get-Metadata -Path $metadataFile -PropertyName ModuleVersion) | Should -BeOfType [Version]
    }

    # It "module is imported with default prefix" {
    #     $prefix = Get-Metadata -Path $metadataFile -PropertyName DefaultCommandPrefix

    #     Import-Module $metadataFile -Force -ErrorAction Stop
    #     (Get-Command -Module "JiraAgilePS").Name | ForEach-Object {
    #         $_ | Should -Match "\-$prefix"
    #     }
    # }

    # It "module is imported with custom prefix" {
    #     $prefix = "Wiki"

    #     Import-Module $metadataFile -Prefix $prefix -Force -ErrorAction Stop
    #     (Get-Command -Module "JiraAgilePS").Name | ForEach-Object {
    #         $_ | Should -Match "\-$prefix"
    #     }
    # }
}
