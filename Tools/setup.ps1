#requires -Modules @{ ModuleName='PowerShellGet'; ModuleVersion='1.6.0' }

[CmdletBinding()]
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingWriteHost', '')]
param()

$psScriptAnalyzerSettingsPath = Join-Path (Join-Path $PSScriptRoot '..') 'PSScriptAnalyzerSettings.psd1'
$buildRequirements = Import-PowerShellDataFile -Path (Join-Path -Path $PSScriptRoot -ChildPath 'build.requirements.psd1')
$standardsRequirement = $buildRequirements |
    Where-Object { $_.ModuleName -eq 'AtlassianPS.Standards' } |
    Select-Object -First 1

if (-not $standardsRequirement) {
    throw 'AtlassianPS.Standards is missing from Tools/build.requirements.psd1.'
}

$standardsVersion = [string] $standardsRequirement.RequiredVersion

function Sync-PSScriptAnalyzerSetting {
    [CmdletBinding()]
    param()

    Write-Host "Syncing PSScriptAnalyzer settings from AtlassianPS.Standards"

    try {
        Import-Module AtlassianPS.Standards -RequiredVersion $standardsVersion -Force -ErrorAction Stop
        $resolvedSettingsPath = Sync-AtlassianPSScriptAnalyzerSettings `
            -DestinationPath $psScriptAnalyzerSettingsPath `
            -ErrorAction Stop
        Write-Host "Shared PSScriptAnalyzer settings synchronized to '$resolvedSettingsPath'."
    }
    catch {
        throw "Unable to sync PSScriptAnalyzer settings from AtlassianPS.Standards. $($_.Exception.Message)"
    }
}

# PowerShell 5.1 and bellow need the PSGallery to be intialized
if (-not ($gallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue)) {
    Write-Host "Installing PackageProvider NuGet"
    $null = Install-PackageProvider -Name NuGet -Force -ErrorAction SilentlyContinue
    Register-PSRepository -Default -ErrorAction SilentlyContinue
    $gallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
    if (-not $gallery) {
        throw "Unable to register the default PSGallery repository."
    }
}

# Make PSGallery trusted, to aviod a confirmation in the console
if ($gallery -and -not ($gallery.Trusted)) {
    Write-Host "Trusting PSGallery"
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted -ErrorAction SilentlyContinue
}

Write-Host "Installing InvokeBuild"
Install-Module InvokeBuild -Scope CurrentUser -Force

Write-Host "Installing Dependencies"
Import-Module "$PSScriptRoot/BuildTools.psm1" -Force
Install-Dependency

Sync-PSScriptAnalyzerSetting
