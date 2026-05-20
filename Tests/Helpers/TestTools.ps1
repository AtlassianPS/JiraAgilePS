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

function Get-FileEncoding {
    [CmdletBinding()]
    [OutputType('EncodingInfo')]
    param (
        [Parameter(Mandatory, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript( { Test-Path $_ -PathType Leaf } )]
        [Alias('FullName')]
        [String]$Path,

        [Switch]$IncludeBinary
    )

    begin {
        $signatures = [Ordered]@{
            'UTF32-LE'   = 'FF-FE-00-00'
            'UTF32-BE'   = '00-00-FE-FF'
            'UTF8-BOM'   = 'EF-BB-BF'
            'UTF16-LE'   = 'FF-FE'
            'UTF16-BE'   = 'FE-FF'
            'UTF7'       = '2B-2F-76-38', '2B-2F-76-39', '2B-2F-76-2B', '2B-2F-76-2F'
            'UTF1'       = 'F7-64-4C'
            'UTF-EBCDIC' = 'DD-73-66-73'
            'SCSU'       = '0E-FE-FF'
            'BOCU-1'     = 'FB-EE-28'
            'GB-18030'   = '84-31-95-33'
        }

        if ($IncludeBinary) {
            $signatures += [Ordered]@{
                'LNK'      = '4C-00-00-00-01-14-02-00'
                'MSEXCEL'  = '50-4B-03-04-14-00-06-00'
                'PNG'      = '89-50-4E-47-0D-0A-1A-0A'
                'MSOFFICE' = 'D0-CF-11-E0-A1-B1-1A-E1'
                '7ZIP'     = '37-7A-BC-AF-27-1C'
                'RTF'      = '7B-5C-72-74-66-31'
                'GIF'      = '47-49-46-38'
                'REGPOL'   = '50-52-65-67'
                'JPEG'     = 'FF-D8'
                'MSEXE'    = '4D-5A'
                'ZIP'      = '50-4B'
            }
        }

        [String[]]$keys = $signatures.Keys
        foreach ($name in $keys) {
            [System.Collections.Generic.List[System.Collections.Generic.List[Byte]]]$values = foreach ($value in $signatures[$name]) {
                [System.Collections.Generic.List[Byte]]$signatureBytes = foreach ($byte in $value.Split('-')) {
                    [Convert]::ToByte($byte, 16)
                }
                , $signatureBytes
            }
            $signatures[$name] = $values
        }
    }

    process {
        try {
            $Path = $pscmdlet.GetUnresolvedProviderPathFromPSPath($Path)

            $bytes = [Byte[]]::new(8)
            $stream = New-Object System.IO.StreamReader($Path)
            $null = $stream.Peek()
            $enc = $stream.CurrentEncoding
            $stream.Close()
            $stream = [System.IO.File]::OpenRead($Path)
            $null = $stream.Read($bytes, 0, $bytes.Count)
            $bytes = [System.Collections.Generic.List[Byte]]$bytes
            $stream.Close()

            if ($enc -eq [System.Text.Encoding]::UTF8) {
                $encoding = "UTF8"
            }

            foreach ($name in $signatures.Keys) {
                $sampleEncoding = foreach ($sequence in $signatures[$name]) {
                    $sample = $bytes.GetRange(0, $sequence.Count)

                    if ([System.Linq.Enumerable]::SequenceEqual($sample, $sequence)) {
                        $name
                        break
                    }
                }
                if ($sampleEncoding) {
                    $encoding = $sampleEncoding
                    break
                }
            }

            if (-not $encoding) {
                $encoding = "ASCII"
            }

            [PSCustomObject]@{
                Name      = Split-Path $Path -Leaf
                Extension = [System.IO.Path]::GetExtension($Path)
                Encoding  = $encoding
                Path      = $Path
            } | Add-Member -TypeName 'EncodingInfo' -PassThru
        }
        catch {
            $pscmdlet.WriteError($_)
        }
    }
}
