#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.9.0"; MaximumVersion = "5.9.999" }

Describe 'AtlassianPS.Standards release blueprint consistency' -Tag Unit {
    BeforeAll {
        . "$PSScriptRoot/../Helpers/TestTools.ps1"
        $script:projectRoot = Resolve-ProjectRoot
        $script:standardsActionSha = 'f691d79ab6b5e44b67db390f6a61ebf00e2f7293'

        $requirements = Import-PowerShellDataFile -Path (Join-Path $script:projectRoot 'Tools/build.requirements.psd1')
        $standardsRequirement = $requirements |
            Where-Object ModuleName -EQ 'AtlassianPS.Standards' |
            Select-Object -First 1
        $script:standardsVersion = [string]$standardsRequirement.RequiredVersion
        $script:workflowRoot = Join-Path $script:projectRoot '.github/workflows'
        $script:buildScript = Get-Content (Join-Path $script:projectRoot 'JiraAgilePS.build.ps1') -Raw
    }

    It 'pins every Standards workflow dependency to the released build dependency' {
        $matches = foreach ($workflow in Get-ChildItem $script:workflowRoot -Filter '*.yml') {
            $content = Get-Content -LiteralPath $workflow.FullName -Raw
            [regex]::Matches(
                $content,
                'AtlassianPS/AtlassianPS\.Standards/\.github/(?:actions/[^\s@]+|workflows/module_release\.yml)@(?<sha>[0-9a-f]{40})\s+#\s+v(?<version>\d+\.\d+\.\d+)'
            )
        }

        @($matches).Count | Should -BeGreaterThan 0
        @($matches | ForEach-Object { $_.Groups['sha'].Value } | Select-Object -Unique) |
            Should -Be @($script:standardsActionSha)
        @($matches | ForEach-Object { $_.Groups['version'].Value } | Select-Object -Unique) |
            Should -Be @($script:standardsVersion)
    }

    It 'uses a safe pull-request-target release intent workflow' {
        $content = Get-Content (Join-Path $script:workflowRoot 'release_intent.yml') -Raw

        $content | Should -Match 'pull_request_target:'
        $content | Should -Match 'pull-requests:\s+read'
        $content | Should -Match 'issues:\s+write'
        $content | Should -Match 'validate-release-intent@[0-9a-f]{40}'
        $content | Should -Not -Match 'actions/checkout|\brun:'
    }

    It 'uses the shared continuous release workflow' {
        $content = Get-Content (Join-Path $script:workflowRoot 'continuous_release.yml') -Raw

        $content | Should -Match 'workflow_run:'
        $content | Should -Match 'workflows:\s*\[CI\]'
        $content | Should -Match 'workflows/module_release\.yml@[0-9a-f]{40}'
        $content | Should -Match 'module-name:\s*JiraAgilePS'
        $content | Should -Match 'issues:\s+read'
    }

    It 'builds and verifies the exact release candidate in CI' {
        $content = Get-Content (Join-Path $script:workflowRoot 'ci.yml') -Raw

        $content | Should -Match ([regex]::Escape("^Prepare (?<tag>v\d+\.\d+\.\d+) release$"))
        $content | Should -Match 'build-release-notes@[0-9a-f]{40}'
        $content | Should -Match 'Invoke-Build -Task SetVersion -VersionToPublish'
        $content | Should -Match 'Invoke-Build -Task VerifyReleaseArtifact -VersionToPublish'
        $script:buildScript | Should -Match 'Task VerifyReleaseArtifact Package'
        $script:buildScript | Should -Match '-ExpectedVersion\s+\$expectedVersion'
        $script:buildScript | Should -Match '-RequireReleaseNotes'
    }

    It 'does not retain the legacy tag release workflow or build publish task' {
        Join-Path $script:workflowRoot 'release.yml' | Should -Not -Exist
        $script:buildScript | Should -Not -Match 'Task Publish\b|PSGalleryAPIKey|Publish-Module'
    }

    It 'keeps source release notes empty until release preparation' {
        $manifest = Import-PowerShellDataFile (Join-Path $script:projectRoot 'JiraAgilePS/JiraAgilePS.psd1')

        $manifest.PrivateData.PSData.ReleaseNotes | Should -BeNullOrEmpty
        $script:buildScript | Should -Match 'Task SetSourceVersion'
        $script:buildScript | Should -Match 'Get-AtlassianPSReleaseNotesFromChangelog[\s\S]+-ReleaseNotes\s+\$releaseNotes'
    }

    It 'keeps GitHub Actions dependency updates non-releasing' {
        $content = Get-Content (Join-Path $script:projectRoot '.github/dependabot.yml') -Raw

        $content | Should -Match 'package-ecosystem:\s*"github-actions"[\s\S]+labels:[\s\S]+- dependencies[\s\S]+- github_actions[\s\S]+- "release:none"'
    }

    It 'reads the Standards version from build.requirements in local tooling' {
        $setupScript = Get-Content (Join-Path $script:projectRoot 'Tools/setup.ps1') -Raw

        $setupScript | Should -Match '\$buildRequirements\s*=\s*Import-PowerShellDataFile'
        $setupScript | Should -Match '-RequiredVersion\s+\$standardsVersion'
        $script:buildScript | Should -Match '\$buildRequirements\s*=\s*Import-PowerShellDataFile'
        $script:buildScript | Should -Match '-RequiredVersion\s+\$standardsRequirement\.RequiredVersion'
    }
}
