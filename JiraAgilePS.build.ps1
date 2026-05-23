#requires -Modules @{ ModuleName = 'AtlassianPS.Standards'; ModuleVersion = '0.1.2'; MaximumVersion = '0.1.2' }

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
    [String[]] $ExcludeTag
)

if ($VersionToPublish) {
    $VersionToPublish = $VersionToPublish.TrimStart('v')
}

Import-Module "$PSScriptRoot/Tools/BuildTools.psm1" -Force

$ProjectName = 'JiraAgilePS'
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
    if (-not (Test-Path $env:BHModulePath)) { return }
    $docsRoot = Join-Path $env:BHProjectPath 'docs'

    $isHelpOutputDir = {
        param($dir)
        $files = @(Get-ChildItem $dir.FullName -File -ErrorAction SilentlyContinue)
        if ($files.Count -eq 0) { return $false }
        @($files | Where-Object { $_.Name -notlike '*.help.txt' -and $_.Name -notlike '*-help.xml' }).Count -eq 0
    }
    $helpDirs = Get-ChildItem $env:BHModulePath -Directory -ErrorAction SilentlyContinue |
        Where-Object { & $isHelpOutputDir $_ }

    foreach ($localeDir in $helpDirs) {
        $localeDocs = Join-Path $docsRoot $localeDir.Name
        if (-not (Test-Path $localeDocs)) {
            Remove-Item $localeDir.FullName -Recurse -Force
            continue
        }

        $expected = [System.Collections.Generic.HashSet[string]]::new(
            [System.StringComparer]::OrdinalIgnoreCase)

        $hasCommandHelp = Get-ChildItem (Join-Path $localeDocs 'commands/*.md') -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne 'index.md' } |
            Select-Object -First 1
        if ($hasCommandHelp) {
            $null = $expected.Add("$env:BHProjectName-help.xml")
        }

        Get-ChildItem (Join-Path $localeDocs 'about_*.md') -File -ErrorAction SilentlyContinue |
            ForEach-Object { $null = $expected.Add("$($_.BaseName).help.txt") }

        Get-ChildItem $localeDir.FullName -File -ErrorAction SilentlyContinue |
            Where-Object { -not $expected.Contains($_.Name) } |
            Remove-Item -Force
    }
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
    Import-Module Microsoft.PowerShell.PlatyPS -Force

    try {
        foreach ($locale in (Get-ChildItem "$env:BHProjectPath/docs" -Attribute Directory)) {
            $outputPath = "$env:BHModulePath/$($locale.Basename)"
            $null = New-Item -ItemType Directory -Path $outputPath -Force

            $commandHelpFiles = Get-ChildItem "$($locale.FullName)/commands/*.md" -File |
                Where-Object { $_.Name -ne 'index.md' -and $_.Name -notlike 'about_*.md' }

            if ($commandHelpFiles) {
                try {
                    $commandHelp = @($commandHelpFiles | Import-MarkdownCommandHelp)
                    $commandHelp | Export-MamlCommandHelp -OutputFolder $outputPath -Force

                    $nestedPath = Join-Path $outputPath $env:BHProjectName
                    if (Test-Path $nestedPath) {
                        Get-ChildItem $nestedPath -Filter '*.xml' | Move-Item -Destination $outputPath -Force
                        Remove-Item $nestedPath -Recurse -Force
                    }

                    $mamlFile = Join-Path $outputPath "$env:BHProjectName-help.xml"
                    Assert-True (Test-Path $mamlFile) "Expected MAML help file was not created: $mamlFile"

                    $xml = [xml](Get-Content $mamlFile -Raw)
                    $ns = [System.Xml.XmlNamespaceManager]::new($xml.NameTable)
                    $ns.AddNamespace('command', 'http://schemas.microsoft.com/maml/dev/command/2004/10')
                    $ns.AddNamespace('dev', 'http://schemas.microsoft.com/maml/dev/2004/10')
                    $ns.AddNamespace('maml', 'http://schemas.microsoft.com/maml/2004/10')
                    foreach ($help in $commandHelp) {
                        $cmdNode = $xml.SelectSingleNode("//command:command[command:details/command:name='$($help.Title)']", $ns)
                        if (-not $cmdNode) { continue }

                        $exNodes = @($cmdNode.SelectNodes('command:examples/command:example', $ns))
                        for ($i = 0; $i -lt $exNodes.Count -and $i -lt $help.Examples.Count; $i++) {
                            $ex = $exNodes[$i]
                            $remarksMd = $help.Examples[$i].Remarks
                            if (-not $remarksMd) { continue }
                            $codeText = ''
                            $proseText = $remarksMd
                            $fence = [regex]::Match($remarksMd, '(?s)```[a-zA-Z0-9_+\-]*\r?\n(.*?)\r?\n```')
                            if ($fence.Success) {
                                $codeText = $fence.Groups[1].Value.TrimEnd()
                                $proseText = ($remarksMd.Substring(0, $fence.Index) + $remarksMd.Substring($fence.Index + $fence.Length)).Trim()
                            }
                            $intro = $ex.SelectSingleNode('maml:introduction', $ns)
                            if ($intro) { [void]$ex.RemoveChild($intro) }
                            $codeNode = $ex.SelectSingleNode('dev:code', $ns)
                            if (-not $codeNode) {
                                $codeNode = $xml.CreateElement('dev', 'code', 'http://schemas.microsoft.com/maml/dev/2004/10')
                                [void]$ex.AppendChild($codeNode)
                            }
                            $codeNode.InnerText = $codeText
                            $remarksNode = $ex.SelectSingleNode('dev:remarks', $ns)
                            if (-not $remarksNode) {
                                $remarksNode = $xml.CreateElement('dev', 'remarks', 'http://schemas.microsoft.com/maml/dev/2004/10')
                                [void]$ex.AppendChild($remarksNode)
                            }
                            while ($remarksNode.HasChildNodes) { [void]$remarksNode.RemoveChild($remarksNode.FirstChild) }
                            foreach ($para in ($proseText -split "\r?\n\r?\n")) {
                                if (-not $para.Trim()) { continue }
                                $pn = $xml.CreateElement('maml', 'para', 'http://schemas.microsoft.com/maml/2004/10')
                                $pn.InnerText = $para
                                [void]$remarksNode.AppendChild($pn)
                            }
                        }

                        $paramMap = @{}
                        foreach ($p in $help.Parameters) { $paramMap[$p.Name] = $p }
                        foreach ($pNode in $cmdNode.SelectNodes('.//command:parameter', $ns)) {
                            $pName = $pNode.SelectSingleNode('maml:name', $ns).InnerText
                            if (-not $paramMap.ContainsKey($pName)) { continue }
                            $p = $paramMap[$pName]
                            $aliasText = if ($p.Aliases) { $p.Aliases -join ', ' } else { 'none' }
                            $pNode.SetAttribute('aliases', $aliasText)
                            $byVal = $false; $byName = $false
                            foreach ($set in $p.ParameterSets) {
                                if ($set.ValueFromPipeline) { $byVal = $true }
                                if ($set.ValueFromPipelineByPropertyName) { $byName = $true }
                            }
                            $pipelineText = if ($byVal -and $byName) {
                                'True (ByValue, ByPropertyName)'
                            }
                            elseif ($byVal) { 'True (ByValue)' }
                            elseif ($byName) { 'True (ByPropertyName)' }
                            else { 'False' }
                            $pNode.SetAttribute('pipelineInput', $pipelineText)
                            if ($pNode.ParentNode.LocalName -eq 'parameters' -and $p.DefaultValue) {
                                $existing = $pNode.SelectSingleNode('dev:defaultValue', $ns)
                                if ($existing) { $pNode.RemoveChild($existing) | Out-Null }
                                $dv = $xml.CreateElement('dev', 'defaultValue', 'http://schemas.microsoft.com/maml/dev/2004/10')
                                $dv.InnerText = $p.DefaultValue
                                $null = $pNode.AppendChild($dv)
                            }
                        }
                    }
                    $xml.Save($mamlFile)
                }
                catch {
                    throw "PlatyPS v1 command-help import failed for locale '$($locale.Basename)'. Ensure docs/<locale>/commands markdown is v1-compatible. $($_.Exception.Message)"
                }
            }

            $utf8Bom = [System.Text.UTF8Encoding]::new($true)
            Get-ChildItem "$($locale.FullName)/about_*.md" -File | ForEach-Object {
                $helpTxtName = $_.BaseName + '.help.txt'
                $content = [System.IO.File]::ReadAllText($_.FullName)
                $content = $content -replace '\A---\r?\n[\s\S]*?\r?\n---\r?\n?', ''
                [System.IO.File]::WriteAllText((Join-Path $outputPath $helpTxtName), $content, $utf8Bom)
            }
        }
    }
    finally {
        Remove-Module Microsoft.PowerShell.PlatyPS -ErrorAction SilentlyContinue
    }
}

Task UpdateManifest {
    $null = Update-AtlassianPSModuleManifestExports `
        -SourceModulePath $env:BHModulePath `
        -BuiltManifestPath $builtManifestPath `
        -ModuleName $env:BHProjectName
}

Task SetVersion {
    $versionString = Set-AtlassianPSModuleManifestVersion `
        -BuiltManifestPath $builtManifestPath `
        -ModuleName $env:BHProjectName `
        -VersionToPublish $VersionToPublish
    Write-Build Gray "Resolved release version: $versionString"
}

Task Test {
    $integrationPath = Join-Path $env:BHBuildOutput 'Tests/Integration'

    $null = Invoke-AtlassianPSModuleTests `
        -TestPath "$env:BHBuildOutput/Tests" `
        -PesterVerbosity $PesterVerbosity `
        -Tag $Tag `
        -ExcludeTag $ExcludeTag `
        -DefaultExcludeTag @('Integration') `
        -ExcludePath @($integrationPath) `
        -MinimumPesterVersion ([Version]'5.7.0')
}

Task Publish SetVersion, SignCode, Package, {
    Assert-True (-not [String]::IsNullOrEmpty($PSGalleryAPIKey)) "No key for the PSGallery"
    Publish-AtlassianPSModuleRelease -BuildOutputPath $env:BHBuildOutput -ModuleName $env:BHProjectName -ApiKey $PSGalleryAPIKey
}, UpdateHomepage

Task UpdateHomepage {
    # TODO:
}

Task SignCode {
    # TODO: waiting for certificates
}

Task Package {
    $null = New-AtlassianPSModulePackage -BuildOutputPath $env:BHBuildOutput -ModuleName $env:BHProjectName
}

Task . Clean, Build, Test
