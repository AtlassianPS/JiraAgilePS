#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.9.0"; MaximumVersion = "5.9.999" }

Describe 'GitHub Actions workflow triggers' -Tag Unit {
    BeforeAll {
        $script:workflowRoot = Join-Path "$PSScriptRoot/../.." '.github/workflows'
    }

    It 'starts continuous release only for completed CI runs on master' {
        $workflow = Get-Content (Join-Path $script:workflowRoot 'continuous_release.yml') -Raw

        $workflow | Should -Match '(?ms)workflow_run:.*?workflows:\s*\[CI\].*?types:\s*\[completed\].*?branches:\s*\[master\]'
    }

    It 'runs integration tests weekly and on demand' {
        $workflow = Get-Content (Join-Path $script:workflowRoot 'integration_tests.yml') -Raw

        $workflow | Should -Match 'cron:\s*"30 5 \* \* 0"'
        $workflow | Should -Match 'workflow_dispatch:'
    }
}
