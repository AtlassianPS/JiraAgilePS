#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe 'AtlassianPS.Standards release blueprint consistency' -Tag Unit {
    BeforeAll {
        $envProjectPath = if ($env:BHProjectPath) {
            Resolve-Path -LiteralPath $env:BHProjectPath -ErrorAction SilentlyContinue
        }
        $hasEnvProjectMarker = $envProjectPath -and (
            (Test-Path -LiteralPath (Join-Path -Path $env:BHProjectPath -ChildPath 'CODEOWNERS')) -or
            (Test-Path -LiteralPath (Join-Path -Path $env:BHProjectPath -ChildPath 'JiraAgilePS.build.ps1'))
        )

        $script:projectRoot = if ($hasEnvProjectMarker) {
            (Resolve-Path -LiteralPath $env:BHProjectPath).ProviderPath
        }
        else {
            $candidate = (Resolve-Path -LiteralPath $PSScriptRoot).ProviderPath
            while ($candidate -and ($candidate -ne [System.IO.Path]::GetPathRoot($candidate))) {
                if (
                    (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'CODEOWNERS')) -or
                    (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'JiraAgilePS.build.ps1'))
                ) {
                    break
                }

                $candidate = Split-Path -Path $candidate -Parent
            }

            if (-not $candidate -or -not (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'JiraAgilePS.build.ps1'))) {
                throw "Could not resolve repository root from '$PSScriptRoot'."
            }

            $candidate
        }

        $buildRequirementsPath = Join-Path -Path $script:projectRoot -ChildPath 'Tools/build.requirements.psd1'
        $buildRequirements = Import-PowerShellDataFile -Path $buildRequirementsPath
        $standardsRequirement = $buildRequirements |
            Where-Object { $_.ModuleName -eq 'AtlassianPS.Standards' } |
            Select-Object -First 1

        $script:standardsVersion = [string] $standardsRequirement.RequiredVersion
        $script:releaseWorkflowContent = Get-Content -LiteralPath (Join-Path -Path $script:projectRoot -ChildPath '.github/workflows/release.yml') -Raw
        $script:buildScriptContent = Get-Content -LiteralPath (Join-Path -Path $script:projectRoot -ChildPath 'JiraAgilePS.build.ps1') -Raw
    }

    It 'pins all Standards workflow actions to the released SHA with matching version comments' {
        $workflowPaths = Get-ChildItem -Path (Join-Path -Path $script:projectRoot -ChildPath '.github/workflows') -File -Filter '*.yml' |
            Select-Object -ExpandProperty FullName

        $workflowActionMatches = foreach ($workflowPath in $workflowPaths) {
            $workflowContent = Get-Content -LiteralPath $workflowPath -Raw
            [regex]::Matches(
                $workflowContent,
                'AtlassianPS/AtlassianPS\.Standards/\.github/actions/[^@\s]+@(?<sha>[^\s]+)\s+#\s*v(?<version>[0-9]+\.[0-9]+\.[0-9]+)'
            ) | ForEach-Object {
                [PSCustomObject]@{
                    WorkflowPath = $workflowPath
                    Sha          = $_.Groups['sha'].Value
                    Version      = $_.Groups['version'].Value
                }
            }
        }

        @($workflowActionMatches).Count | Should -BeGreaterThan 0
        foreach ($sha in ($workflowActionMatches | Select-Object -ExpandProperty Sha)) {
            $sha | Should -Match '^[0-9a-f]{40}$'
        }
        ($workflowActionMatches | Select-Object -ExpandProperty Sha -Unique) | Should -Be @('6fe5d05db84cdd10c9e4284e235a8f359c9537ad')
        ($workflowActionMatches | Select-Object -ExpandProperty Version -Unique) | Should -Be @($script:standardsVersion)
    }

    It 'uses the shared release tag resolver action' {
        $script:releaseWorkflowContent | Should -Match 'AtlassianPS/AtlassianPS\.Standards/\.github/actions/resolve-release-tag@[0-9a-f]{40}'
        $script:releaseWorkflowContent | Should -Not -Match 'git rev-list -n 1|Tools/Resolve-ReleaseTag\.ps1'
    }

    It 'builds release notes before publishing and uses them for the GitHub release body' {
        $script:releaseWorkflowContent | Should -Match 'AtlassianPS/AtlassianPS\.Standards/\.github/actions/build-release-notes@[0-9a-f]{40}'
        $script:releaseWorkflowContent | Should -Match 'body_path:\s+\$\{\{\s*steps\.release_notes\.outputs\.release_notes_path\s*\}\}'
        $script:releaseWorkflowContent | Should -Match 'build-release-notes[\s\S]+Publish module'
    }

    It 'does not keep old changelog release plumbing' {
        $forbiddenPath = Join-Path -Path $script:projectRoot -ChildPath '.github/changelog.configuration.json'
        $forbiddenPath | Should -Not -Exist

        $repositoryText = Get-ChildItem -Path $script:projectRoot -Recurse -File |
            Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]|[\\/]Release[\\/]|[\\/]Tests[\\/]Tools[\\/]StandardsVersionConsistency\.Unit\.Tests\.ps1$' } |
            ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw -ErrorAction SilentlyContinue }

        $repositoryText | Should -Not -Match 'changelog-to-release|changelog\.configuration\.json|steps\.changelog\.outputs\.body'
        $script:releaseWorkflowContent | Should -Not -Match 'write-file|Set-Content|Out-File'
        $script:buildScriptContent | Should -Not -Match 'Get-AtlassianPSReleaseNotesFromChangelog[\s\S]+Set-Content'
    }

    It 'sources published manifest release notes from the changelog through Standards' {
        $script:buildScriptContent | Should -Match 'Get-AtlassianPSReleaseNotesFromChangelog[\s\S]+CHANGELOG\.md'
        $script:buildScriptContent | Should -Match 'Set-AtlassianPSModuleManifestVersion[\s\S]+-ReleaseNotes\s+\$releaseNotes'
    }

    It 'reads the Standards version from build.requirements in local tooling' {
        $setupScriptContent = Get-Content -LiteralPath (Join-Path -Path $script:projectRoot -ChildPath 'Tools/setup.ps1') -Raw
        $buildScriptContent = Get-Content -LiteralPath (Join-Path -Path $script:projectRoot -ChildPath 'JiraAgilePS.build.ps1') -Raw

        $setupScriptContent | Should -Match '\$buildRequirements\s*=\s*Import-PowerShellDataFile'
        $setupScriptContent | Should -Match '-RequiredVersion\s+\$standardsVersion'
        $setupScriptContent | Should -Not -Match "AtlassianPS\.Standards.*RequiredVersion\s+'[0-9]+\.[0-9]+\.[0-9]+'"

        $buildScriptContent | Should -Match '\$buildRequirements\s*=\s*Import-PowerShellDataFile'
        $buildScriptContent | Should -Match '-RequiredVersion\s+\$standardsRequirement\.RequiredVersion'
        $buildScriptContent | Should -Not -Match "AtlassianPS\.Standards.*RequiredVersion\s+'[0-9]+\.[0-9]+\.[0-9]+'"
    }
}
