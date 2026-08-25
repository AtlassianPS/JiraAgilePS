#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.9.0"; MaximumVersion = "5.9.999" }

Describe 'GitHub workflow resource policy' -Tag Unit {
    BeforeAll {
        . "$PSScriptRoot/../Helpers/TestTools.ps1"
        $script:projectRoot = Resolve-ProjectRoot
        $script:workflowRoot = Join-Path $script:projectRoot '.github/workflows'
    }

    It 'does not rerun release intent validation for pull request edits' {
        $content = Get-Content (Join-Path $script:workflowRoot 'release_intent.yml') -Raw

        $content | Should -Not -Match 'types:\s*\[[^\]]*\bedited\b'
        $content | Should -Match 'types:\s*\[[^\]]*\bsynchronize\b'
        $content | Should -Match 'types:\s*\[[^\]]*\blabeled\b'
        $content | Should -Match 'types:\s*\[[^\]]*\bunlabeled\b'
    }

    It 'limits routine dependency checks and integration artifacts' {
        $dependabot = Get-Content (Join-Path $script:projectRoot '.github/dependabot.yml') -Raw
        $integration = Get-Content (Join-Path $script:workflowRoot 'integration_tests.yml') -Raw

        ([regex]::Matches($dependabot, 'package-ecosystem:\s*"(?:devcontainers|docker|docker-compose)"[\s\S]*?interval:\s*"?monthly"?')).Count | Should -Be 3
        $dependabot | Should -Match 'package-ecosystem:\s*"github-actions"[\s\S]*?interval:\s*"?weekly"?'
        ([regex]::Matches($integration, 'retention-days:\s+14')).Count | Should -Be 2
        ([regex]::Matches($integration, 'retention-days:\s+7')).Count | Should -Be 1
        ([regex]::Matches($integration, "failure\(\) \|\| inputs\.debug \|\| runner\.debug == '1'")).Count | Should -Be 2
    }
}
