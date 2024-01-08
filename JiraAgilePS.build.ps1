#requires -Modules InvokeBuild
#requires -Modules @{ ModuleName = 'Pester'; RequiredVersion = '5.5.0' }

[CmdletBinding()]
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingWriteHost', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingEmptyCatchBlock', '')]
param(
    [String[]]$Tag,
    [String[]]$ExcludeTag = @("Integration")
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

#region SetUp
task Setup GetNextVersion
# Synopsis: Initialize the build environment
task Init {
    Import-Module "$PSScriptRoot/Tools/BuildTools.psm1" -Force -ErrorAction Stop

    Import-Module BuildHelpers -Force -ErrorAction Stop
    Set-BuildEnvironment -BuildOutput '$ProjectPath/Release' -ErrorAction SilentlyContinue
    $env:BHInvokeBuild = "true"
}

# Synopsis: Get the next version for the build
task GetNextVersion Init, {
    $manifestVersion = [Version](Get-Metadata -Path $env:BHPSModuleManifest)
    try {
        $env:CurrentOnlineVersion = [Version](Find-Module -Name $env:BHProjectName).Version
        $nextOnlineVersion = Get-NextNugetPackageVersion -Name $env:BHProjectName -ErrorAction Stop

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
task ShowInfo Setup, {
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
} , RemoveBuildVariables
#endregion DebugInformation

#region BuildRelease
# Synopsis: Build a shippable release
task Build Setup, GenerateExternalHelp, CopyModuleFiles, UpdateManifest, CompileModule

# Synopsis: Generate ./Release structure
task CopyModuleFiles {
    # Setup
    if (-not (Test-Path "$env:BHBuildOutput")) {
        $null = New-Item -Path "$env:BHBuildOutput" -ItemType Directory
    }

    # Copy module
    Copy-Item -Path "$env:BHModulePath/*" -Destination "$env:BHBuildOutput" -Recurse -Force
    # Copy additional files
    Copy-Item -Path @(
        "$env:BHProjectPath/CHANGELOG.md"
        "$env:BHProjectPath/LICENSE"
        "$env:BHProjectPath/README.md"
    ) -Destination "$env:BHBuildOutput" -Force
}

# Synopsis: Compile all functions into the .psm1 file
task CompileModule {
    $regionsToKeep = @('Dependencies', 'Configuration')

    $targetFile = "$env:BHBuildOutput/$env:BHProjectName.psm1"
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

    $PublicFunctions = @( Get-ChildItem -Path "$env:BHBuildOutput/Public/*.ps1" -ErrorAction SilentlyContinue )
    $PrivateFunctions = @( Get-ChildItem -Path "$env:BHBuildOutput/Private/*.ps1" -ErrorAction SilentlyContinue )

    foreach ($function in @($PublicFunctions + $PrivateFunctions)) {
        $compiled += (Get-Content -Path $function.FullName -Raw)
        $compiled += "`r`n"
    }

    Set-Content -LiteralPath $targetFile -Value $compiled -Encoding UTF8 -Force
    Remove-Utf8Bom -Path $targetFile

    "Private", "Public" | ForEach-Object { Remove-Item -Path "$env:BHBuildOutput/$_" -Recurse -Force }
}

# Synopsis: Use PlatyPS to generate External-Help
task GenerateExternalHelp {
    Import-Module platyPS -Force
    foreach ($locale in (Get-ChildItem "$env:BHProjectPath/docs" -Attribute Directory)) {
        New-ExternalHelp -Path "$($locale.FullName)" -OutputPath "$env:BHModulePath/$($locale.Basename)" -Force
        New-ExternalHelp -Path "$($locale.FullName)/commands" -OutputPath "$env:BHModulePath/$($locale.Basename)" -Force
    }
    Remove-Module platyPS
}

# Synopsis: Update the manifest of the module
task UpdateManifest {
    Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
    Import-Module $env:BHPSModuleManifest -Force
    $ModuleAlias = @(Get-Alias | Where-Object { $_.ModuleName -eq "$env:BHProjectName" })

    Update-Metadata -Path "$env:BHBuildOutput/$env:BHProjectName.psd1" -PropertyName ModuleVersion -Value $env:NextBuildVersion
    # BuildHelpers\Update-Metadata -Path "$env:BHBuildOutput/$env:BHProjectName.psd1" -PropertyName FileList -Value (Get-ChildItem "$env:BHBuildOutput" -Recurse).Name
    BuildHelpers\Set-ModuleFunctions -Name "$env:BHBuildOutput/$env:BHProjectName.psd1" -FunctionsToExport ([string[]](Get-ChildItem "$env:BHBuildOutput/Public/*.ps1").BaseName)
    Update-Metadata -Path "$env:BHBuildOutput/$env:BHProjectName.psd1" -PropertyName AliasesToExport -Value ''
    if ($ModuleAlias) {
        Update-Metadata -Path "$env:BHBuildOutput/$env:BHProjectName.psd1" -PropertyName AliasesToExport -Value @($ModuleAlias.Name)
    }

    $Prerelease = ''
    if ("$env:BHBranchName" -notin @('master', 'main')) {
        $Prerelease = "$env:BHBranchName".ToLower() -replace '[^a-zA-Z0-9]'
    }
    Update-Metadata -Path "$env:BHBuildOutput/$env:BHProjectName.psd1" -PropertyName Prerelease -Value $Prerelease

}

# Synopsis: Create a ZIP file with this build
task Package Setup, {
    Assert-True { Test-Path "$env:BHBuildOutput\$env:BHProjectName" } "Missing files to package"

    Remove-Item "$env:BHBuildOutput\$env:BHProjectName.zip" -ErrorAction SilentlyContinue
    $null = Compress-Archive -Path "$env:BHBuildOutput\*" -DestinationPath "$env:BHBuildOutput\$env:BHProjectName.zip"
}
#endregion BuildRelease

#region Test
task Test Setup, {
    $psVersion = $PSVersionTable.PSVersion.ToString()
    Assert-True { Test-Path $env:BHBuildOutput -PathType Container } "Release path must exist"

    Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue

    $pesterConfiguration = [PesterConfiguration]@{
        Run        = @{
            Path  = "$env:BHProjectPath/Tests/*"
            Exist = $true
            Throw = $true
        }
        Filter     = @{
            Tag        = $Tag
            ExcludeTag = $ExcludeTag
        }
        TestResult = @{
            Enabled      = $true
            OutputFormat = "NUnitXml"
            OutputPath   = "testResults-$OS-$psVersion.xml"
        }
        Output     = @{ }
    }

    Invoke-Pester -Configuration $pesterConfiguration
}, RemoveTestResults
#endregion

#region Publish
# Synopsis: Publish a new release on github and the PSGallery
task Publish Setup, PublishToGallery, TagReplository, UpdateHomepage, RemoveBuildVariables

# Synpsis: Publish the $release to the PSGallery
task PublishToGallery {
    $PSGalleryAPIKey = $env:NUGET_API_KEY
    # Assert-True (-not [String]::IsNullOrEmpty($PSGalleryAPIKey)) "No key for the PSGallery"
    # Assert-True { Get-Module $env:BHProjectName -ListAvailable } "Module $env:BHProjectName is not available"

    Remove-Module $env:BHProjectName -ErrorAction Ignore
    Import-Module "$env:BHBuildOutput/JiraAgilePS" -ErrorAction Stop

    # Publish-Module -Name $env:BHProjectName -NuGetApiKey $PSGalleryAPIKey -WhatIf
    Write-Build -Color "Red" "Running 'Publish-Module'"
}

# Synopsis: push a tag with the version to the git repository
task TagReplository GetNextVersion, Package, {
    # $GithubAccessToken = $env:GITHUB_TOKEN
    # Assert-True (-not [String]::IsNullOrEmpty($GithubAccessToken)) "No key for the PSGallery"
    # $releaseText = "Release version $env:NextBuildVersion"

    # Set-GitUser

    # # Push a tag to the repository
    # Write-Build Gray "git checkout $ENV:BHBranchName"
    # cmd /c "git checkout $ENV:BHBranchName 2>&1"

    # Write-Build Gray "git tag -a v$env:NextBuildVersion -m `"$releaseText`""
    # cmd /c "git tag -a v$env:NextBuildVersion -m `"$releaseText`" 2>&1"

    # Write-Build Gray "git push origin v$env:NextBuildVersion"
    # cmd /c "git push origin v$env:NextBuildVersion 2>&1"

    # Write-Build Gray "Publish v$env:NextBuildVersion as a GitHub release"
    # $release = @{
    #     AccessToken     = $GithubAccessToken
    #     TagName         = "v$env:NextBuildVersion"
    #     Name            = "Version $env:NextBuildVersion"
    #     ReleaseText     = $releaseText
    #     RepositoryOwner = "AtlassianPS"
    #     Artifact        = "$env:BHBuildOutput\$env:BHProjectName.zip" # TODO: probably not the right file
    # }
    # Publish-GithubRelease @release
    Write-Build "executing Publish-GithubRelease"
}

# Synopsis: Update the version of this module that the homepage uses
task UpdateHomepage {
    # try {
    #     Set-GitUser

    #     Write-Build Gray "git close .../AtlassianPS.github.io --recursive"
    #     $null = cmd /c "git clone https://github.com/AtlassianPS/AtlassianPS.github.io --recursive 2>&1"

    #     Push-Location "AtlassianPS.github.io/"

    #     Write-Build Gray "git submodule foreach git pull origin master"
    #     $null = cmd /c "git submodule foreach git pull origin master 2>&1"

    #     Write-Build Gray "git status -s"
    #     $status = cmd /c "git status -s 2>&1"

    #     if ($status -contains " M modules/$env:BHProjectName") {
    #         Write-Build Gray "git add modules/$env:BHProjectName"
    #         $null = cmd /c "git add modules/$env:BHProjectName 2>&1"

    #         Write-Build Gray "git commit -m `"Update module $env:BHProjectName`""
    #         cmd /c "git commit -m `"Update module $env:BHProjectName`" 2>&1"

    #         Write-Build Gray "git push"
    #         cmd /c "git push 2>&1"
    #     }

    #     Pop-Location
    # }
    # catch { Write-Warning "Failed to deploy to homepage" }
    Write-Build "Updating homepage"
}
#endregion Publish

#region Cleaning tasks
# Synopsis: Clean the working dir
task Clean Setup, RemoveGeneratedFiles, RemoveTestResults #, RemoveBuildVariables

# Synopsis: Remove generated and temp files.
task RemoveGeneratedFiles {
    Remove-Item "$env:BHModulePath/en-US/*" -Force -ErrorAction SilentlyContinue
    Remove-Item $env:BHBuildOutput -Force -Recurse -ErrorAction SilentlyContinue
}

# Synopsis: Remove Pester results
task RemoveTestResults {
    Remove-Item "Test-*.xml" -Force -ErrorAction SilentlyContinue
}

# Synopsis: Remove build variables
task RemoveBuildVariables {
    Remove-Item -Path Env:\BH*
}
#endregion

task . Clean, Build, Test

