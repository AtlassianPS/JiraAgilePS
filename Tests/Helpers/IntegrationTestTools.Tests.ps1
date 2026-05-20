#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe "IntegrationTestTools helper functions" -Tag 'Unit' {
    BeforeAll {
        . "$PSScriptRoot/TestTools.ps1"
        . "$PSScriptRoot/IntegrationTestTools.ps1"

        $script:trackedEnvVars = @(
            'CI_JIRA_TYPE',
            'CI_JIRA_URL',
            'CI_JIRA_ADMIN',
            'CI_JIRA_ADMIN_PASSWORD',
            'CI_JIRA_USER',
            'CI_JIRA_USER_PASSWORD',
            'JIRA_CLOUD_URL',
            'JIRA_CLOUD_USERNAME',
            'JIRA_CLOUD_PASSWORD',
            'JIRA_CLOUD_USERNAME_NORMAL',
            'JIRA_CLOUD_PASSWORD_NORMAL',
            'JIRA_TEST_PROJECT',
            'JIRA_TEST_ISSUE',
            'JIRA_TEST_USER',
            'JIRA_TEST_GROUP',
            'JIRA_TEST_FILTER',
            'JIRA_TEST_VERSION',
            'JIRA_TEST_READONLY',
            'JIRA_TEST_VERBOSE',
            'DOTENV_QUOTED_VALUE',
            'DOTENV_INLINE_COMMENT'
        )
    }

    BeforeEach {
        $script:envBackup = @{}
        foreach ($name in $trackedEnvVars) {
            $script:envBackup[$name] = [System.Environment]::GetEnvironmentVariable($name)
            [System.Environment]::SetEnvironmentVariable($name, $null)
        }

        $testRootBase = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath ".tmp"
        $null = New-Item -Path $testRootBase -ItemType Directory -Force
        $script:testRoot = Join-Path -Path $testRootBase -ChildPath "integration-env-tests-$([Guid]::NewGuid().ToString('N'))"
        $null = New-Item -Path $script:testRoot -ItemType Directory -Force

        $script:_CachedIntegrationEnv = $null
        $script:_EnvLoaded = $false
        $script:_CleanupInProgress = $false
        Remove-Variable -Name _JiraAgilePSIntegrationEnvWarned -Scope Global -ErrorAction SilentlyContinue
    }

    AfterEach {
        foreach ($name in $trackedEnvVars) {
            [System.Environment]::SetEnvironmentVariable($name, $script:envBackup[$name])
        }
        Remove-Variable -Name _JiraAgilePSIntegrationEnvWarned -Scope Global -ErrorAction SilentlyContinue

        Remove-Item -Path $script:testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    Context "Read-DotEnvFile" {
        It "parses quoted and inline-comment values" {
            $envPath = Join-Path -Path $testRoot -ChildPath ".env"
            @(
                "# comment"
                "DOTENV_QUOTED_VALUE=""value#withhash"""
                "DOTENV_INLINE_COMMENT=value  # comment"
            ) | Set-Content -Path $envPath -Encoding utf8

            Read-DotEnvFile -Path $envPath

            [System.Environment]::GetEnvironmentVariable('DOTENV_QUOTED_VALUE') | Should -Be "value#withhash"
            [System.Environment]::GetEnvironmentVariable('DOTENV_INLINE_COMMENT') | Should -Be "value"
        }
    }

    Context "Initialize-IntegrationEnvironment" {
        It "returns null when cloud required variables are missing" {
            Mock Resolve-ProjectRoot { $script:testRoot }

            $result = Initialize-IntegrationEnvironment -WarningAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It "returns cloud configuration when required variables are set" {
            Mock Resolve-ProjectRoot { $script:testRoot }

            [System.Environment]::SetEnvironmentVariable('JIRA_CLOUD_URL', 'https://cloud.example.com')
            [System.Environment]::SetEnvironmentVariable('JIRA_CLOUD_USERNAME', 'user@example.com')
            [System.Environment]::SetEnvironmentVariable('JIRA_CLOUD_PASSWORD', 'token')
            [System.Environment]::SetEnvironmentVariable('JIRA_TEST_PROJECT', 'AG')
            [System.Environment]::SetEnvironmentVariable('JIRA_TEST_ISSUE', 'AG-1')

            $result = Initialize-IntegrationEnvironment -WarningAction SilentlyContinue

            $result | Should -Not -BeNullOrEmpty
            $result.DeploymentType | Should -Be 'Cloud'
            $result.IsCloud | Should -BeTrue
            $result.UserIdProperty | Should -Be 'accountId'
            $result.TestProject | Should -Be 'AG'
            $result.TestIssue | Should -Be 'AG-1'
        }

        It "returns server configuration when required variables are set" {
            Mock Resolve-ProjectRoot { $script:testRoot }

            [System.Environment]::SetEnvironmentVariable('CI_JIRA_TYPE', 'Server')
            [System.Environment]::SetEnvironmentVariable('CI_JIRA_URL', 'http://localhost:2990/jira')
            [System.Environment]::SetEnvironmentVariable('CI_JIRA_ADMIN', 'admin')
            [System.Environment]::SetEnvironmentVariable('CI_JIRA_ADMIN_PASSWORD', 'admin')
            [System.Environment]::SetEnvironmentVariable('CI_JIRA_USER', 'jira_user')
            [System.Environment]::SetEnvironmentVariable('CI_JIRA_USER_PASSWORD', 'jira')

            $result = Initialize-IntegrationEnvironment -WarningAction SilentlyContinue

            $result | Should -Not -BeNullOrEmpty
            $result.DeploymentType | Should -Be 'Server'
            $result.IsCloud | Should -BeFalse
            $result.UserIdProperty | Should -Be 'name'
            $result.TestProject | Should -Be 'TEST'
        }
    }
}
