[CmdletBinding()]
param(
    [ValidateSet('None', 'Normal' , 'Detailed', 'Diagnostic')]
    [String] $PesterVerbosity = 'Normal',

    [Parameter()]
    [String] $VersionToPublish,

    [Parameter()]
    [String] $PSGalleryAPIKey,

    [Parameter()]
    [String[]] $Tag,

    [Parameter()]
    [String[]] $ExcludeTag,

    [Parameter()]
    [ValidateRange(1, 16)]
    [Int] $ThrottleLimit = 4,

    [Parameter()]
    [String[]] $IntegrationTestPath
)

Import-Module "$PSScriptRoot/Tools/BuildTools.psm1" -Force

function Import-JiraAgilePSStandard {
    [CmdletBinding()]
    param()

    $buildRequirements = Import-PowerShellDataFile -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Tools/build.requirements.psd1')
    $standardsRequirement = $buildRequirements |
        Where-Object { $_.ModuleName -eq 'AtlassianPS.Standards' } |
        Select-Object -First 1

    if (-not $standardsRequirement) {
        throw 'AtlassianPS.Standards is missing from Tools/build.requirements.psd1.'
    }

    Import-Module AtlassianPS.Standards -RequiredVersion $standardsRequirement.RequiredVersion -Force -ErrorAction Stop
}

$ProjectName = 'JiraAgilePS'
Import-JiraAgilePSStandard

$script:BuildInfo = Initialize-AtlassianPSBuildEnvironment `
    -ProjectName $ProjectName `
    -ProjectPath $PSScriptRoot `
    -VersionToPublish $VersionToPublish `
    -ResetBuildEnvironmentVariables

$builtManifestPath = $script:BuildInfo.BuiltManifestPath

Task ShowDebugInfo {
    Write-AtlassianPSBuildInfo -BuildInfo $script:BuildInfo
}

Task ShowInfo ShowDebugInfo

Task Lint {
    $analyzerPaths = @(
        "$env:BHProjectPath/JiraAgilePS"
        "$env:BHProjectPath/Tests"
        "$env:BHProjectPath/Tools"
        "$env:BHProjectPath/JiraAgilePS.build.ps1"
    )

    $null = Invoke-AtlassianPSLint `
        -ProjectPath $env:BHProjectPath `
        -ModulePath $env:BHModulePath `
        -BuildScriptPath "$env:BHProjectPath/JiraAgilePS.build.ps1" `
        -StyleTestPath "$env:BHProjectPath/Tests/Style.Tests.ps1" `
        -AnalyzerSettingsPath "$env:BHProjectPath/PSScriptAnalyzerSettings.psd1" `
        -AnalyzerPaths $analyzerPaths `
        -PesterVerbosity $PesterVerbosity `
        -Severity @('Error', 'Warning')
}

Task Clean {
    Remove-Item $env:BHBuildOutput -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item "Test*.xml" -Force -ErrorAction SilentlyContinue
    # `JiraAgilePS/<locale>/` is preserved as the GenerateExternalHelp incremental cache.
}

Task Build Clean, {
    if (-not (Test-Path "$env:BHBuildOutput/$env:BHProjectName")) {
        $null = New-Item -Path "$env:BHBuildOutput", "$env:BHBuildOutput/$env:BHProjectName" -ItemType Directory
    }
}, GenerateExternalHelp, RemoveOrphanedExternalHelp, CopyModuleFiles, CompileModule, UpdateManifest

Task RemoveOrphanedExternalHelp {
    Remove-AtlassianPSOrphanedExternalHelp `
        -ModulePath $env:BHModulePath `
        -DocsPath (Join-Path $env:BHProjectPath 'docs') `
        -ModuleName $env:BHProjectName
}

Task CopyModuleFiles {
    $additionalFiles = @(
        'CHANGELOG.md'
        'LICENSE'
        'README.md'
    )

    $null = Copy-AtlassianPSModuleArtifacts `
        -ProjectPath $env:BHProjectPath `
        -ModuleName $env:BHProjectName `
        -BuildOutputPath $env:BHBuildOutput `
        -AdditionalFiles $additionalFiles `
        -IncludeTests

    Copy-Item -Path "$env:BHProjectPath/PSScriptAnalyzerSettings.psd1" -Destination $env:BHBuildOutput -Force
}

Task CompileModule {
    $null = Join-AtlassianPSModuleSource `
        -ReleaseModulePath "$env:BHBuildOutput/$env:BHProjectName" `
        -RegionsToKeep @('Dependencies', 'Configuration')
}

Task GenerateExternalHelp -Inputs {
    Get-ChildItem "$env:BHProjectPath/docs" -Recurse -File -Filter '*.md'
} -Outputs {
    foreach ($locale in (Get-ChildItem "$env:BHProjectPath/docs" -Attribute Directory)) {
        $localeOut = Join-Path $env:BHModulePath $locale.BaseName

        $hasCommandHelp = Get-ChildItem "$($locale.FullName)/commands/*.md" -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne 'index.md' } |
            Select-Object -First 1
        if ($hasCommandHelp) {
            Join-Path $localeOut "$env:BHProjectName-help.xml"
        }

        Get-ChildItem "$($locale.FullName)/about_*.md" -File -ErrorAction SilentlyContinue |
            ForEach-Object { Join-Path $localeOut "$($_.BaseName).help.txt" }
    }
} {
    Update-AtlassianPSExternalHelp `
        -DocsPath (Join-Path $env:BHProjectPath 'docs') `
        -ModulePath $env:BHModulePath `
        -ModuleName $env:BHProjectName
}

Task UpdateManifest {
    $null = Update-AtlassianPSModuleManifestExports `
        -SourceModulePath $env:BHModulePath `
        -BuiltManifestPath $builtManifestPath `
        -ModuleName $env:BHProjectName
}

Task SetVersion {
    $releaseNotes = Get-AtlassianPSReleaseNotesFromChangelog `
        -ChangelogPath (Join-Path -Path $env:BHProjectPath -ChildPath 'CHANGELOG.md') `
        -ReleaseVersion $script:BuildInfo.VersionToPublish

    $versionString = Set-AtlassianPSModuleManifestVersion `
        -BuiltManifestPath $builtManifestPath `
        -ModuleName $env:BHProjectName `
        -VersionToPublish $VersionToPublish `
        -ReleaseNotes $releaseNotes
    Write-Build Gray "Resolved release version: $versionString"
}

Task Test {
    $integrationPath = Join-Path $env:BHBuildOutput 'Tests/Integration'
    $integrationTestFiles = @()
    if (Test-Path $integrationPath) {
        $integrationTestFiles = @(Get-ChildItem -Path $integrationPath -Filter '*.Tests.ps1' -File | Select-Object -ExpandProperty FullName)
    }

    $null = Invoke-AtlassianPSModuleTests `
        -TestPath "$env:BHBuildOutput/Tests" `
        -PesterVerbosity $PesterVerbosity `
        -Tag $Tag `
        -ExcludeTag $ExcludeTag `
        -DefaultExcludeTag @('Integration') `
        -ExcludePath $integrationTestFiles `
        -MinimumPesterVersion ([Version]'5.7.0')
}

# Synopsis: Run integration tests against live Jira Agile (Cloud or Data Center; no build required)
Task TestIntegration {
    $integrationHelperPath = Join-Path $env:BHProjectPath 'Tests/Helpers/IntegrationTestTools.ps1'
    if (Test-Path $integrationHelperPath) {
        . $integrationHelperPath
        Read-DotEnvFile -Path (Join-Path $env:BHProjectPath '.env')
    }

    $deploymentType = if ($env:CI_JIRA_TYPE) { $env:CI_JIRA_TYPE } else { 'Cloud' }
    if ($deploymentType -notin @('Cloud', 'Server')) {
        throw "Invalid CI_JIRA_TYPE '$deploymentType'. Must be 'Cloud' or 'Server'."
    }

    $requiredEnvVars = if ($deploymentType -eq 'Server') {
        @(
            'CI_JIRA_URL'
            'CI_JIRA_ADMIN'
            'CI_JIRA_ADMIN_PASSWORD'
            'CI_JIRA_USER'
            'CI_JIRA_USER_PASSWORD'
        )
    }
    else {
        @(
            'JIRA_CLOUD_URL'
            'JIRA_CLOUD_USERNAME'
            'JIRA_CLOUD_PASSWORD'
            'JIRA_TEST_PROJECT'
            'JIRA_TEST_ISSUE'
        )
    }

    $missing = $requiredEnvVars | Where-Object {
        [string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable($_))
    }
    if ($missing) {
        throw @"
Required environment variables for the $deploymentType integration test track are not set: $($missing -join ', ')

For CI: Configure Cloud values as repository variables/secrets; Server values are supplied by the Docker workflow job.
For local development: Copy .env.example to .env and configure the relevant track before running integration tests.
See Tests/Integration/README.md for integration test configuration details.
"@
    }

    $testPath = if ($IntegrationTestPath) { $IntegrationTestPath } else { @("$env:BHProjectPath/Tests/Integration") }
    $config = New-PesterConfiguration
    $config.Run.Path = $testPath
    $config.Run.PassThru = $true
    $config.Output.Verbosity = $PesterVerbosity
    $config.TestResult.Enabled = $true
    $config.TestResult.OutputFormat = 'NUnitXml'
    $config.TestResult.OutputPath = 'Test-Integration.xml'

    if ($Tag) {
        $config.Filter.Tag = $Tag
        Write-Build Gray "Running integration tests with tag(s): $($Tag -join ', ')"
    }
    else {
        $config.Filter.Tag = @('Integration')
        Write-Build Gray 'Running integration tests (tag: Integration)'
    }
    if ($ExcludeTag) {
        $config.Filter.ExcludeTag = $ExcludeTag
        Write-Build Gray "Excluding tag(s): $($ExcludeTag -join ', ')"
    }
    if ($ThrottleLimit -ne 4) {
        Write-Build Gray "ThrottleLimit is accepted for JiraPS parity but direct Pester execution is sequential in JiraAgilePS. Requested: $ThrottleLimit"
    }

    $result = Invoke-Pester -Configuration $config
    $failedContainerCount = @($result.Containers | Where-Object { $_.Result -eq 'Failed' }).Count
    Assert-True ($result.FailedCount -eq 0 -and $failedContainerCount -eq 0) "Integration tests failed: $($result.FailedCount) failed tests, $failedContainerCount failed containers, $($result.PassedCount) passed, $($result.SkippedCount) skipped."
    Assert-True ($result.PassedCount -gt 0) "Integration tests did not execute any passing tests. Check the selected path and tags."
}

# Synopsis: Start the local Jira Data Center Docker container (for Server-track integration tests)
Task StartJiraDocker {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw 'Docker is required for the Jira Server track. See https://docs.docker.com/get-docker/.'
    }
    $composeFile = Join-Path $env:BHProjectPath 'docker-compose.yml'
    Assert-True (Test-Path $composeFile) "docker-compose.yml not found at $composeFile"
    Write-Build Gray "Starting Jira Data Center container via $composeFile (cold start: ~5 min)..."
    Invoke-BuildExec { docker compose -f $composeFile up -d }
    & (Join-Path $env:BHProjectPath 'Tools/Wait-JiraServer.ps1')
}

# Synopsis: Stop the local Jira Data Center Docker container
Task StopJiraDocker {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw 'Docker is required for the Jira Server track. See https://docs.docker.com/get-docker/.'
    }
    $composeFile = Join-Path $env:BHProjectPath 'docker-compose.yml'
    Assert-True (Test-Path $composeFile) "docker-compose.yml not found at $composeFile"
    Write-Build Gray "Stopping Jira Data Center container ($composeFile)..."
    Invoke-BuildExec { docker compose -f $composeFile down -v }
}

Task Publish SetVersion, Package, {
    Assert-True (-not [String]::IsNullOrEmpty($PSGalleryAPIKey)) "No key for the PSGallery"
    Publish-Module -Path (Join-Path $env:BHBuildOutput $env:BHProjectName) -NuGetApiKey $PSGalleryAPIKey
}

Task SignCode {
    throw "Code signing is not configured yet. Add certificate provisioning before wiring this task into Publish."
}

Task Package {
    $script:PackagePath = New-AtlassianPSModulePackage -BuildOutputPath $env:BHBuildOutput -ModuleName $env:BHProjectName
}

Task TestPublish Build, Package, {
    $testPackageParameters = @{
        BuildOutputPath = $env:BHBuildOutput
        ModuleName      = $env:BHProjectName
    }
    if ($script:PackagePath) {
        $testPackageParameters.PackagePath = $script:PackagePath
    }

    $package = Test-AtlassianPSModulePackage @testPackageParameters
    Write-Build Green "Publish dry-run passed: $($package.PackagePath)"
}

Task . Clean, Build, Test
