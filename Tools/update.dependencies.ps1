#requires -Module PowerShellGet

[CmdletBinding()]
param()

$requirementsPath = Join-Path $PSScriptRoot 'build.requirements.psd1'
$setupScriptPath = Join-Path $PSScriptRoot 'setup.ps1'

function Get-LatestModuleVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )

    try {
        $latest = Find-Module -Name $ModuleName -Repository PSGallery -ErrorAction Stop
        return $latest.Version.ToString()
    }
    catch {
        Write-Warning "Unable to resolve latest version for module '$ModuleName'. Keeping existing version."
        Write-Warning $_
        return $null
    }
}

function Update-ArrayRequirements {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'This helper is pure and only returns updated text.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseSingularNouns', '', Justification = 'Name intentionally denotes processing of multiple requirements.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Requirements
    )

    $outputLines = @('@(')
    foreach ($module in $Requirements) {
        if (-not $module.ModuleName -or -not $module.RequiredVersion) {
            continue
        }

        Write-Verbose "Checking for module: $($module.ModuleName)"
        $newVersion = $module.RequiredVersion
        $latestVersion = Get-LatestModuleVersion -ModuleName $module.ModuleName
        if ($latestVersion -and ([version]$latestVersion -gt [version]$module.RequiredVersion)) {
            Write-Verbose "Updating $($module.ModuleName): v$($module.RequiredVersion) --> $latestVersion"
            $newVersion = $latestVersion
        }

        $outputLines += "    @{ ModuleName = `"$($module.ModuleName)`"; RequiredVersion = `"$newVersion`" }"
    }
    $outputLines += ')'

    return ($outputLines -join "`r`n") + "`r`n"
}

function Update-HashtableRequirements {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'This helper is pure and only returns updated text.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseSingularNouns', '', Justification = 'Name intentionally denotes processing of multiple requirements.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Requirements,
        [Parameter(Mandatory = $true)]
        [string]$RawContent
    )

    $updatedContent = $RawContent
    foreach ($key in $Requirements.Keys) {
        if ($key -eq 'PSDependOptions') {
            continue
        }

        $entry = $Requirements[$key]
        $currentVersion = $null
        if ($entry -is [string]) {
            $currentVersion = $entry
        }
        elseif ($entry -is [System.Collections.IDictionary] -and $entry.Contains('Version')) {
            $currentVersion = [string]$entry['Version']
        }

        if (-not $currentVersion -or $currentVersion -eq 'latest') {
            continue
        }

        Write-Verbose "Checking for module: $key"
        $latestVersion = Get-LatestModuleVersion -ModuleName $key
        if (-not $latestVersion -or ([version]$latestVersion -le [version]$currentVersion)) {
            continue
        }

        Write-Verbose "Updating ${key}: v$currentVersion --> $latestVersion"
        $escapedKey = [System.Text.RegularExpressions.Regex]::Escape([string]$key)

        if ($entry -is [string]) {
            $pattern = "(?m)(^\s*['""]?$escapedKey['""]?\s*=\s*['""])([^'""]+)(['""]\s*$)"
        }
        else {
            $pattern = "(?ms)(^\s*['""]?$escapedKey['""]?\s*=\s*@\{.*?^\s*Version\s*=\s*['""])([^'""]+)(['""]\s*$)"
        }

        $updatedContent = [System.Text.RegularExpressions.Regex]::Replace(
            $updatedContent,
            $pattern,
            {
                param($match)
                "$($match.Groups[1].Value)$latestVersion$($match.Groups[3].Value)"
            },
            [System.Text.RegularExpressions.RegexOptions]::Multiline
        )
    }

    $updatedContent = $updatedContent -replace "`r?`n", "`r`n"
    if (-not $updatedContent.EndsWith("`r`n")) {
        $updatedContent += "`r`n"
    }
    return $updatedContent
}

function Update-DependencyRequirement {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if (-not (Test-Path -Path $requirementsPath)) {
        Write-Warning "Dependency file '$requirementsPath' not found."
        return
    }

    $rawContent = [System.IO.File]::ReadAllText($requirementsPath)
    $requirements = Import-PowerShellDataFile -Path $requirementsPath
    $newContent = $null

    if ($requirements -is [array]) {
        $newContent = Update-ArrayRequirements -Requirements $requirements
    }
    elseif ($requirements -is [hashtable]) {
        $newContent = Update-HashtableRequirements -Requirements $requirements -RawContent $rawContent
    }
    else {
        Write-Warning "Unsupported requirements format in '$requirementsPath'."
        return
    }

    if ($newContent -ne $rawContent -and $PSCmdlet.ShouldProcess($requirementsPath, 'Update dependency requirements')) {
        [System.IO.File]::WriteAllText($requirementsPath, $newContent, [System.Text.UTF8Encoding]::new($false))
    }
}

function Update-PinnedPSScriptAnalyzerSettingsUri {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $settingsFilePath = 'standards/PSScriptAnalyzerSettings.psd1'
    $commitApiUri = "https://api.github.com/repos/AtlassianPS/.github/commits?path=$settingsFilePath&sha=master&per_page=1"

    Write-Output "Checking pinned .github commit for $settingsFilePath"
    try {
        $response = Invoke-RestMethod -Uri $commitApiUri -Method Get -ErrorAction Stop
    }
    catch {
        throw "Unable to query latest commit for shared PSScriptAnalyzer settings. $($_.Exception.Message)"
    }

    if (-not $response -or -not $response[0] -or -not $response[0].sha) {
        throw "No commit data returned for shared PSScriptAnalyzer settings."
    }

    $latestCommit = $response[0].sha
    $newUri = "https://raw.githubusercontent.com/AtlassianPS/.github/$latestCommit/$settingsFilePath"
    $setupContent = [System.IO.File]::ReadAllText($setupScriptPath)
    $oldUriPattern = "(?m)^\$psScriptAnalyzerSettingsUri = 'https://raw\.githubusercontent\.com/AtlassianPS/\.github/[^']+/standards/PSScriptAnalyzerSettings\.psd1'$"
    $newUriLine = "`$psScriptAnalyzerSettingsUri = '$newUri'"

    if ($setupContent -notmatch $oldUriPattern) {
        Write-Warning "Unable to locate pinned PSScriptAnalyzer URI in setup.ps1; skipping."
        return
    }

    $updatedContent = [System.Text.RegularExpressions.Regex]::Replace($setupContent, $oldUriPattern, $newUriLine, [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if ($updatedContent -eq $setupContent) {
        Write-Output "Pinned PSScriptAnalyzer URI already up to date."
        return
    }

    if ($PSCmdlet.ShouldProcess($setupScriptPath, 'Update pinned PSScriptAnalyzer settings URI')) {
        $updatedContent = $updatedContent -replace "`r?`n", "`r`n"
        [System.IO.File]::WriteAllText($setupScriptPath, $updatedContent, [System.Text.UTF8Encoding]::new($false))
        Write-Output "Updated pinned PSScriptAnalyzer URI to commit $latestCommit"
    }
}

Update-DependencyRequirement
Update-PinnedPSScriptAnalyzerSettingsUri
