#requires -Modules InvokeBuild

[CmdletBinding()]
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingWriteHost', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingEmptyCatchBlock', '')]
param(
    [String[]]$Tag,
    [String[]]$ExcludeTag = @("Integration"),
    [String]$PSGalleryAPIKey,
    [String]$GithubAccessToken
)

$WarningPreference = "Continue"
if ($PSBoundParameters.ContainsKey('Verbose')) {
    $VerbosePreference = "Continue"
}
if ($PSBoundParameters.ContainsKey('Debug')) {
    $DebugPreference = "Continue"
}

try {
    $script:IsWindows = (-not (Get-Variable -Name IsWindows -ErrorAction Ignore)) -or $IsWindows
    $script:IsLinux = (Get-Variable -Name IsLinux -ErrorAction Ignore) -and $IsLinux
    $script:IsMacOS = (Get-Variable -Name IsMacOS -ErrorAction Ignore) -and $IsMacOS
    $script:IsCoreCLR = $PSVersionTable.ContainsKey('PSEdition') -and $PSVersionTable.PSEdition -eq 'Core'
}
catch { }

Set-StrictMode -Version Latest

Import-Module "$PSScriptRoot/Tools/BuildTools.psm1" -Force -ErrorAction Stop

if ($BuildTask -notin @("SetUp", "InstallDependencies")) {
    Import-Module BuildHelpers -Force -ErrorAction Stop
    Invoke-Init
}

#region SetUp
# Synopsis: Proxy task
task Init { Invoke-Init }

# Synopsis: Create an initial environment for developing on the module
task SetUp InstallDependencies, Build

# Synopsis: Install all module used for the development of this module
task InstallDependencies {
    Install-Dependency
}

# Synopsis: Get the next version for the build
task GetNextVersion {
    $manifestVersion = [Version](Get-Metadata -Path $env:BHPSModuleManifest)
    try {
        $env:CurrentOnlineVersion = [Version](Find-Module -Name $env:BHProjectName).Version
        $nextOnlineVersion = Get-NextNugetPackageVersion -Name $env:BHProjectName

        if ( ($manifestVersion.Major -gt $nextOnlineVersion.Major) -or
            ($manifestVersion.Minor -gt $nextOnlineVersion.Minor)
            # -or ($manifestVersion.Build -gt $nextOnlineVersion.Build)
        ) {
            $env:NextBuildVersion = [Version]::New($manifestVersion.Major, $manifestVersion.Minor, 0)
        }
        else {
            $env:NextBuildVersion = $nextOnlineVersion
        }
    }
    catch {
        $env:NextBuildVersion = $manifestVersion
    }
}
#endregion Setup

#region HarmonizeVariables
switch ($true) {
    { $IsWindows } {
        $OS = "Windows"
        if (-not ($IsCoreCLR)) {
            $OSVersion = $PSVersionTable.BuildVersion.ToString()
        }
    }
    { $IsLinux } {
        $OS = "Linux"
    }
    { $IsMacOs } {
        $OS = "OSX"
    }
    { $IsCoreCLR } {
        $OSVersion = $PSVersionTable.OS
    }
}
#endregion HarmonizeVariables

#region DebugInformation
task ShowInfo Init, GetNextVersion, {
    Write-Build Gray
    Write-Build Gray ('Running in:                 {0}' -f $env:BHBuildSystem)
    Write-Build Gray '-------------------------------------------------------'
    Write-Build Gray
    Write-Build Gray ('Project name:               {0}' -f $env:BHProjectName)
    Write-Build Gray ('Project root:               {0}' -f $env:BHProjectPath)
    Write-Build Gray ('Build Path:                 {0}' -f $env:BHBuildOutput)
    Write-Build Gray ('Current (online) Version:   {0}' -f $env:CurrentOnlineVersion)
    Write-Build Gray '-------------------------------------------------------'
    Write-Build Gray
    Write-Build Gray ('Branch:                     {0}' -f $env:BHBranchName)
    Write-Build Gray ('Commit:                     {0}' -f $env:BHCommitMessage)
    Write-Build Gray ('Build #:                    {0}' -f $env:BHBuildNumber)
    Write-Build Gray ('Next Version:               {0}' -f $env:NextBuildVersion)
    Write-Build Gray '-------------------------------------------------------'
    Write-Build Gray
    Write-Build Gray ('PowerShell version:         {0}' -f $PSVersionTable.PSVersion.ToString())
    Write-Build Gray ('OS:                         {0}' -f $OS)
    Write-Build Gray ('OS Version:                 {0}' -f $OSVersion)
    Write-Build Gray
}

# Synopsis: Compatibility alias expected by shared setup action
task ShowDebugInfo ShowInfo
#endregion DebugInformation

#region Lint
# Synopsis: Run style checks and PSScriptAnalyzer.
task Lint Init, {
    $failures = [System.Collections.Generic.List[String]]::new()

    Write-Build Gray "Running style tests..."

    $pesterConfigHash = @{
        Run    = @{
            PassThru = $true
            Path     = "$env:BHProjectPath/Tests/Style.Tests.ps1"
        }
        Output = @{
            Verbosity = "Normal"
        }
    }

    $pesterConfig = New-PesterConfiguration -Hashtable $pesterConfigHash
    $testResults = Invoke-Pester -Configuration $pesterConfig
    if ($testResults.FailedCount -gt 0) {
        $failures.Add("$($testResults.FailedCount) style test(s) failed.")
    }
    else {
        Write-Build Green "Style tests: passed."
    }

    Write-Build Gray "Running PSScriptAnalyzer..."
    $projectPath = (Resolve-Path $PSScriptRoot).Path
    $analyzerRoots = @(
        (Resolve-Path (Join-Path $projectPath 'JiraAgilePS')).Path
        (Resolve-Path (Join-Path $projectPath 'Tests')).Path
        (Resolve-Path (Join-Path $projectPath 'Tools')).Path
    )
    $analyzerParams = @{
        Settings = (Resolve-Path (Join-Path $projectPath 'PSScriptAnalyzerSettings.psd1')).Path
        Severity = @('Error', 'Warning')
    }

    $analyzerFiles = @(
        foreach ($root in $analyzerRoots) {
            Get-ChildItem -Path $root -Recurse -File -Include *.ps1, *.psm1
        }
    )
    $analyzerFiles += Get-Item (Resolve-Path (Join-Path $projectPath 'JiraAgilePS.build.ps1')).Path

    $results = @(
        foreach ($file in $analyzerFiles) {
            try {
                Invoke-ScriptAnalyzer -Path $file.FullName @analyzerParams
            }
            catch {
                throw "Invoke-ScriptAnalyzer failed for file '$($file.FullName)': $($_.Exception.Message)"
            }
        }
    )

    if ($results.Count -gt 0) {
        foreach ($result in $results) {
            $color = if ($result.Severity -eq 'Error') { 'Red' } else { 'Yellow' }
            $location = if ($result.ScriptName) { $result.ScriptName } else { '<unknown>' }
            Write-Build $color "[$($result.Severity)] ${location}:$($result.Line) - $($result.RuleName): $($result.Message)"
        }
        $failures.Add("$($results.Count) PSScriptAnalyzer issue(s) found.")
    }
    else {
        Write-Build Green "PSScriptAnalyzer: no issues found."
    }

    if ($failures.Count -gt 0) {
        throw ("Lint failed:`n  - " + ($failures -join "`n  - "))
    }
}
#endregion Lint

#region BuildRelease
# Synopsis: Build a shippable release
task Build Init, GenerateExternalHelp, CopyModuleFiles, UpdateManifest, CompileModule, PrepareTests

# Synopsis: Generate ./Release structure
task CopyModuleFiles {
    # Setup
    $releaseModulePath = "$env:BHBuildOutput/$env:BHProjectName"
    if (Test-Path $releaseModulePath) {
        Remove-Item -Path $releaseModulePath -Recurse -Force
    }
    $null = New-Item -Path $releaseModulePath -ItemType Directory -Force

    # Copy module
    Copy-Item -Path "$env:BHModulePath/*" -Destination $releaseModulePath -Recurse -Force
    # Copy additional files
    Copy-Item -Path @(
        "$env:BHProjectPath/CHANGELOG.md"
        "$env:BHProjectPath/LICENSE"
        "$env:BHProjectPath/README.md"
    ) -Destination $releaseModulePath -Force
}

# Synopsis: Prepare tests for ./Release
task PrepareTests Init, {
    $null = New-Item -Path "$env:BHBuildOutput/Tests" -ItemType Directory -Force -ErrorAction SilentlyContinue

    $testsPath = "$env:BHProjectPath/Tests"
    if (Test-Path $testsPath) {
        Copy-Item -Path $testsPath -Destination $env:BHBuildOutput -Recurse -Force
    }
    else {
        Write-Warning "No Tests directory found at '$testsPath'. Continuing without bundled tests."
    }

    $analyzerSettingsPath = "$env:BHProjectPath/PSScriptAnalyzerSettings.psd1"
    if (Test-Path $analyzerSettingsPath) {
        Copy-Item -Path $analyzerSettingsPath -Destination $env:BHBuildOutput -Force
    }
}

# Synopsis: Compile all functions into the .psm1 file
task CompileModule Init, {
    $regionsToKeep = @('Dependencies', 'Configuration')

    $targetFile = "$env:BHBuildOutput/$env:BHProjectName/$env:BHProjectName.psm1"
    $content = Get-Content -Encoding UTF8 -LiteralPath $targetFile
    $capture = $false
    $compiled = ""

    foreach ($line in $content) {
        if ($line -match "^#region ($($regionsToKeep -join "|"))$") {
            $capture = $true
        }
        if (($capture -eq $true) -and ($line -match "^#endregion")) {
            $capture = $false
        }

        if ($capture) {
            $compiled += "$line`r`n"
        }
    }

    $PublicFunctions = @( Get-ChildItem -Path "$env:BHBuildOutput/$env:BHProjectName/Public/*.ps1" -ErrorAction SilentlyContinue )
    $PrivateFunctions = @( Get-ChildItem -Path "$env:BHBuildOutput/$env:BHProjectName/Private/*.ps1" -ErrorAction SilentlyContinue )

    foreach ($function in @($PublicFunctions + $PrivateFunctions)) {
        $compiled += (Get-Content -Path $function.FullName -Raw)
        $compiled += "`r`n"
    }

    Set-Content -LiteralPath $targetFile -Value $compiled -Encoding UTF8 -Force
    Remove-Utf8Bom -Path $targetFile

    "Private", "Public" | Foreach-Object { Remove-Item -Path "$env:BHBuildOutput/$env:BHProjectName/$_" -Recurse -Force }
}

# Synopsis: Use PlatyPS to generate External-Help
task GenerateExternalHelp Init, {
    if (-not (Get-Module -Name platyPS)) {
        Import-Module platyPS -Force
    }
    $utf8Bom = [System.Text.UTF8Encoding]::new($true)
    foreach ($locale in (Get-ChildItem "$env:BHProjectPath/docs" -Attribute Directory)) {
        $outputPath = "$env:BHModulePath/$($locale.Basename)"
        $null = New-Item -Path $outputPath -ItemType Directory -Force -ErrorAction SilentlyContinue
        Get-ChildItem -Path $outputPath -Filter 'about_*.help.txt' -File -ErrorAction SilentlyContinue | Remove-Item -Force

        New-ExternalHelp -Path "$($locale.FullName)/commands" -OutputPath $outputPath -Force

        $aboutCandidates = @(
            @(Get-ChildItem "$($locale.FullName)/about_*.md" -File -ErrorAction SilentlyContinue)
            @(Get-ChildItem "$($locale.FullName)/about/*.md" -File -ErrorAction SilentlyContinue)
            @(Get-Item "$($locale.FullName)/index.md" -ErrorAction SilentlyContinue)
        ) | Select-Object -Unique

        $topicSources = @{}
        foreach ($aboutFile in $aboutCandidates) {
            if (-not $aboutFile) { continue }

            $content = [System.IO.File]::ReadAllText($aboutFile.FullName)
            $content = $content -replace '\A---\r?\n[\s\S]*?\r?\n---\r?\n?', ''

            $topicMatch = [regex]::Match($content, '(?m)^\s*##\s+(about_[A-Za-z0-9_]+)\s*$')
            if (-not $topicMatch.Success) { continue }
            $topicName = $topicMatch.Groups[1].Value
            if ($topicSources.ContainsKey($topicName)) {
                throw "Duplicate about topic heading '$topicName' found in '$($topicSources[$topicName])' and '$($aboutFile.FullName)'."
            }
            $topicSources[$topicName] = $aboutFile.FullName

            $helpTxtName = "$topicName.help.txt"
            [System.IO.File]::WriteAllText((Join-Path $outputPath $helpTxtName), $content, $utf8Bom)
        }
    }
    Remove-Module platyPS
}

# Synopsis: Update the manifest of the module
task UpdateManifest GetNextVersion, {
    Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
    Import-Module $env:BHPSModuleManifest -Force
    $ModuleAlias = @(Get-Alias | Where-Object { $_.ModuleName -eq "$env:BHProjectName" })

    BuildHelpers\Update-Metadata -Path "$env:BHBuildOutput/$env:BHProjectName/$env:BHProjectName.psd1" -PropertyName ModuleVersion -Value $env:NextBuildVersion
    # BuildHelpers\Update-Metadata -Path "$env:BHBuildOutput/$env:BHProjectName/$env:BHProjectName.psd1" -PropertyName FileList -Value (Get-ChildItem "$env:BHBuildOutput/$env:BHProjectName" -Recurse).Name
    BuildHelpers\Set-ModuleFunctions -Name "$env:BHBuildOutput/$env:BHProjectName/$env:BHProjectName.psd1" -FunctionsToExport ([string[]](Get-ChildItem "$env:BHBuildOutput/$env:BHProjectName/Public/*.ps1").BaseName)
    BuildHelpers\Update-Metadata -Path "$env:BHBuildOutput/$env:BHProjectName/$env:BHProjectName.psd1" -PropertyName AliasesToExport -Value ''
    if ($ModuleAlias) {
        BuildHelpers\Update-Metadata -Path "$env:BHBuildOutput/$env:BHProjectName/$env:BHProjectName.psd1" -PropertyName AliasesToExport -Value @($ModuleAlias.Name)
    }
}

# Synopsis: Create a ZIP file with this build
task Package Init, {
    Assert-True { Test-Path "$env:BHBuildOutput\$env:BHProjectName" } "Missing files to package"

    Remove-Item "$env:BHBuildOutput\$env:BHProjectName.zip" -ErrorAction SilentlyContinue
    $null = Compress-Archive -Path "$env:BHBuildOutput\$env:BHProjectName" -DestinationPath "$env:BHBuildOutput\$env:BHProjectName.zip"
}
#endregion BuildRelease

#region Test
task Test Init, {
    Assert-True { Test-Path $env:BHBuildOutput -PathType Container } "Release path must exist"

    Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue

    $testScriptPath = "$env:BHBuildOutput/Tests"
    $testScripts = @(Get-ChildItem -Path $testScriptPath -Filter '*.ps1' -File -Recurse -ErrorAction SilentlyContinue)
    if (-not $testScripts) {
        Write-Warning "No test files found at '$testScriptPath'. Skipping Test task."
        return
    }

    <# $params = @{
        Path    = "$env:BHBuildOutput/$env:BHProjectName"
        Include = '*.ps1', '*.psm1'
        Recurse = $True
        Exclude = $CodeCoverageExclude
    }
    $codeCoverageFiles = Get-ChildItem @params #>

    $pesterConfigHash = @{
        Run        = @{
            Path     = "$env:BHBuildOutput/Tests/*"
            PassThru = $true
            Exit     = $false
        }
        TestResult = @{
            Enabled      = $true
            OutputFormat = "NUnitXml"
            OutputPath   = "$env:BHProjectPath/Test-$OS-$($PSVersionTable.PSVersion.ToString()).xml"
        }
        Output     = @{
            Verbosity = "Normal"
        }
    }

    if ($Tag) {
        $pesterConfigHash['Filter'] = @{ Tag = $Tag }
    }

    if ($ExcludeTag) {
        if (-not $pesterConfigHash.ContainsKey('Filter')) {
            $pesterConfigHash['Filter'] = @{}
        }
        $pesterConfigHash['Filter']['ExcludeTag'] = $ExcludeTag
    }

    $pesterConfiguration = New-PesterConfiguration -Hashtable $pesterConfigHash
    # $pesterConfiguration.CodeCoverage.Enabled = $true
    # $pesterConfiguration.CodeCoverage.Path = $codeCoverageFiles.FullName

    $testResults = Invoke-Pester -Configuration $pesterConfiguration

    Assert-True ($testResults.Result -eq "Passed") ("Pester run did not pass. " +
        "FailedCount=$($testResults.FailedCount); " +
        "FailedContainersCount=$($testResults.FailedContainersCount); " +
        "FailedBlocksCount=$($testResults.FailedBlocksCount).")
}, { Invoke-Init }
#endregion

#region Publish
# Synopsis: Publish a new release on github and the PSGallery
task Deploy Init, PublishToGallery, TagReplository, UpdateHomepage

# Synpsis: Publish the $release to the PSGallery
task PublishToGallery {
    Assert-True (-not [String]::IsNullOrEmpty($PSGalleryAPIKey)) "No key for the PSGallery"
    Assert-True { Get-Module $env:BHProjectName -ListAvailable } "Module $env:BHProjectName is not available"

    Remove-Module $env:BHProjectName -ErrorAction Ignore

    Publish-Module -Name $env:BHProjectName -NuGetApiKey $PSGalleryAPIKey
}

# Synopsis: Setup git
task SetupGit {
    git config --global user.email "support@atlassianps.net"
    git config --global user.name "AtlassianPS Automated User"
}

# Synopsis: push a tag with the version to the git repository
task TagReplository GetNextVersion, Package, SetupGit, {
    $releaseText = "Release version $env:NextBuildVersion"

    # Push a tag to the repository
    Write-Build Gray "git checkout $ENV:BHBranchName"
    cmd /c "git checkout $ENV:BHBranchName 2>&1"

    Write-Build Gray "git tag -a v$env:NextBuildVersion -m `"$releaseText`""
    cmd /c "git tag -a v$env:NextBuildVersion -m `"$releaseText`" 2>&1"

    Write-Build Gray "git push origin v$env:NextBuildVersion"
    cmd /c "git push origin v$env:NextBuildVersion 2>&1"

    Write-Build Gray "Publish v$env:NextBuildVersion as a GitHub release"
    $release = @{
        AccessToken     = $GithubAccessToken
        TagName         = "v$env:NextBuildVersion"
        Name            = "Version $env:NextBuildVersion"
        ReleaseText     = $releaseText
        RepositoryOwner = "AtlassianPS"
        Artifact        = "$env:BHBuildOutput\$env:BHProjectName.zip"
    }
    Publish-GithubRelease @release
}

# Synopsis: Update the version of this module that the homepage uses
task UpdateHomepage SetupGit, {
    try {
        Write-Build Gray "git close .../AtlassianPS.github.io --recursive"
        $null = cmd /c "git clone https://github.com/AtlassianPS/AtlassianPS.github.io --recursive 2>&1"

        Push-Location "AtlassianPS.github.io/"

        Write-Build Gray "git submodule foreach git pull origin master"
        $null = cmd /c "git submodule foreach git pull origin master 2>&1"

        Write-Build Gray "git status -s"
        $status = cmd /c "git status -s 2>&1"

        if ($status -contains " M modules/$env:BHProjectName") {
            Write-Build Gray "git add modules/$env:BHProjectName"
            $null = cmd /c "git add modules/$env:BHProjectName 2>&1"

            Write-Build Gray "git commit -m `"Update module $env:BHProjectName`""
            cmd /c "git commit -m `"Update module $env:BHProjectName`" 2>&1"

            Write-Build Gray "git push"
            cmd /c "git push 2>&1"
        }

        Pop-Location
    }
    catch { Write-Warning "Failed to deploy to homepage" }
}
#endregion Publish

#region Cleaning tasks
# Synopsis: Clean the working dir
task Clean Init, RemoveGeneratedFiles, RemoveTestResults

# Synopsis: Remove generated and temp files.
task RemoveGeneratedFiles {
    Remove-Item "$env:BHModulePath/en-US/*" -Force -ErrorAction SilentlyContinue
    Remove-Item $env:BHBuildOutput -Force -Recurse -ErrorAction SilentlyContinue
}

# Synopsis: Remove Pester results
task RemoveTestResults {
    Remove-Item "Test-*.xml" -Force -ErrorAction SilentlyContinue
}
#endregion

task . ShowInfo, Clean, Build, Test

Remove-Item -Path Env:\BH*
