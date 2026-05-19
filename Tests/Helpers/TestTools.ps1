# Captured at dot-source time when $PSScriptRoot is this file's directory (Tests/Helpers/)
$script:_TestToolsDir = $PSScriptRoot

function Initialize-TestEnvironment {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $manifestPath = Resolve-ModuleSource
    $moduleDir = Split-Path $manifestPath -Parent

    $fingerprint = (
        Get-ChildItem $moduleDir -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -in '.ps1', '.psm1', '.psd1', '.cs' } |
            ForEach-Object { $_.LastWriteTimeUtc.Ticks } |
            Measure-Object -Maximum
    ).Maximum

    $loaded = Get-Module JiraAgilePS
    if ($loaded -and $loaded.ModuleBase -eq $moduleDir) {
        $cached = & $loaded { $script:__TestImportFingerprint }
        if ($cached -eq $fingerprint) {
            return $manifestPath
        }
    }

    Get-Module |
        Where-Object {
            $_.RequiredModules -and
            (@($_.RequiredModules | ForEach-Object { $_.Name }) -contains 'JiraAgilePS')
        } |
        Remove-Module -Force -ErrorAction SilentlyContinue
    Remove-Module JiraAgilePS -Force -ErrorAction SilentlyContinue

    Import-Module $manifestPath -Force -ErrorAction Stop
    & (Get-Module JiraAgilePS) { param($fp) $script:__TestImportFingerprint = $fp } $fingerprint

    return $manifestPath
}

function Resolve-ModuleSource {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $projectRoot = Resolve-ProjectRoot
    ${/} = [System.IO.Path]::DirectorySeparatorChar

    if ($PSScriptRoot -like "*${/}Release${/}*") {
        $projectRoot = (Resolve-Path "$projectRoot/Release").Path
    }

    $moduleManifest = Join-Path $projectRoot "JiraAgilePS/JiraAgilePS.psd1"

    if (-not (Test-Path $moduleManifest)) {
        throw "Could not find JiraAgilePS module at: $moduleManifest"
    }

    Write-Verbose "Using module at: $moduleManifest"
    return $moduleManifest
}

function Resolve-ProjectRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $candidate = (Resolve-Path $script:_TestToolsDir).Path
    while ($candidate -and ($candidate -ne [System.IO.Path]::GetPathRoot($candidate))) {
        if (
            (Test-Path (Join-Path $candidate "CODEOWNERS")) -or
            (Test-Path (Join-Path $candidate "JiraAgilePS.build.ps1"))
        ) {
            return $candidate
        }
        $candidate = Split-Path $candidate -Parent
    }

    throw "Could not find project root (no repository marker found in any parent of $($script:_TestToolsDir))"
}
