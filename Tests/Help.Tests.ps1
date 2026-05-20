#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
    $script:projectRoot = Resolve-ProjectRoot
}

Describe "Help tests" -Tag "Documentation", "Build" {
    BeforeDiscovery {
        ${/} = [regex]::Escape([System.IO.Path]::DirectorySeparatorChar)

        $script:isRunningInReleaseFolder = $moduleToTest -match "${/}Release${/}"
        if (-not $isRunningInReleaseFolder) {
            Write-Warning "Tests are being run outside of the 'Release' folder. Some tests may be skipped."
        }

        $script:module = Get-Module JiraAgilePS
        $modulePrefix = $module.Prefix

        # Public function files are the canonical source names used in docs.
        $script:publicFunctions = (Get-ChildItem "$projectRoot/JiraAgilePS/Public/*.ps1").BaseName

        # Collect exported command infos and map prefixed command names back to
        # source function names when DefaultCommandPrefix is used.
        $script:commands = Get-Command -Module JiraAgilePS -CommandType Function |
            ForEach-Object {
                $sourceCommandName = $_.Name
                if (
                    -not [string]::IsNullOrWhiteSpace($modulePrefix) -and
                    $_.Name -match '^(?<verb>[^-]+)-(?<noun>.+)$'
                ) {
                    $verb = $Matches.verb
                    $noun = $Matches.noun
                    if ($noun.StartsWith($modulePrefix, [System.StringComparison]::Ordinal)) {
                        $sourceCommandName = "$verb-$($noun.Substring($modulePrefix.Length))"
                    }
                }

                if ($sourceCommandName -in $publicFunctions) {
                    @{
                        Command           = $_
                        CommandName       = $_.Name
                        SourceCommandName = $sourceCommandName
                    }
                }
            }

        $script:DefaultParams = @(
            'Verbose'
            'Debug'
            'ErrorAction'
            'WarningAction'
            'InformationAction'
            'ErrorVariable'
            'WarningVariable'
            'InformationVariable'
            'OutVariable'
            'OutBuffer'
            'PipelineVariable'
            'ProgressAction'
            'WhatIf'
            'Confirm'
            'First'
            'Skip'
            'IncludeTotalCount'
        )

        $aboutDocs = @(
            @(Get-ChildItem "$projectRoot/docs/en-US/about_*.md" -File -ErrorAction SilentlyContinue)
        ) | Select-Object -Unique

        $script:aboutTopicDeclarations = @(
            foreach ($aboutDoc in $aboutDocs) {
                if (-not $aboutDoc) { continue }
                $content = [System.IO.File]::ReadAllText($aboutDoc.FullName)
                $content = $content -replace '\A---\r?\n[\s\S]*?\r?\n---\r?\n?', ''
                $topicMatch = [regex]::Match($content, '(?m)^\s*##\s+(about_[A-Za-z0-9_]+)\s*$')
                if ($topicMatch.Success) {
                    [PSCustomObject]@{
                        TopicName  = $topicMatch.Groups[1].Value
                        SourcePath = $aboutDoc.FullName
                    }
                }
            }
        )

        $script:aboutTopics = @($aboutTopicDeclarations.TopicName | Sort-Object -Unique)
    }
    BeforeAll {
        $script:module = Get-Module JiraAgilePS
    }

    Describe "Public Functions" {
        Context "Command <_.CommandName>" -ForEach $commands {
            BeforeDiscovery {
                if ($isRunningInReleaseFolder) {
                    $cmd = $_.Command
                    $isDontShow = {
                        param($name)
                        $paramAttr = $cmd.Parameters[$name].Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
                        return ($paramAttr.DontShow -contains $true)
                    }
                    $script:parameters = $cmd.Parameters.Keys | Where-Object { $_ -notin $DefaultParams -and -not (& $isDontShow $_) }
                }
                else {
                    $script:parameters = @()
                }
            }
            BeforeAll {
                $script:command = $_.Command
                $script:sourceCommandName = $_.SourceCommandName
                $script:help = if ($isRunningInReleaseFolder) { Get-Help $command.Name }
            }

            Context "Markdown file for <_.SourceCommandName>" {
                BeforeAll {
                    $script:markdownFile = Resolve-Path "$projectRoot/docs/en-US/commands/$sourceCommandName.md" -ErrorAction Stop
                }

                It "is described in a markdown file" {
                    $markdownFile | Should -Not -BeNullOrEmpty
                    Test-Path $markdownFile | Should -Be $true
                }

                It "does not have Comment-Based Help" {
                    # We use .EXAMPLE, as we test this extensively and it is never auto-generated.
                    $command.Definition | Should -Not -BeNullOrEmpty
                    $pattern = [regex]::Escape(".EXAMPLE")

                    $command.Definition | Should -Not -Match "^\s*$pattern"
                }

                It "has no platyPS template artifacts" {
                    $markdownFile | Should -Not -BeNullOrEmpty
                    $markdownFile | Should -Not -FileContentMatch '\{\{.*?\}\}'
                }

                It "has a valid online version" {
                    $pattern = [regex]::Escape("https://atlassianps.org/docs/JiraAgilePS/commands/$sourceCommandName/")

                    $markdownFile | Should -FileContentMatch $pattern
                }

                It "defines the frontmatter for the homepage" {
                    $markdownFile | Should -Not -BeNullOrEmpty
                    $markdownFile | Should -FileContentMatch "Module Name: JiraAgilePS"
                    $markdownFile | Should -FileContentMatchExactly "layout: documentation"
                    $markdownFile | Should -FileContentMatch "permalink: /docs/JiraAgilePS/commands/$sourceCommandName/"
                }
            }

            Context "Help for <_.CommandName>" -Skip:(-not $isRunningInReleaseFolder) {
                It "has a synopsis" {
                    $help.Synopsis | Should -Not -BeNullOrEmpty
                }

                It "has a syntax" {
                    $help.syntax | Should -Not -BeNullOrEmpty
                }

                It "has a description" {
                    $help.Description.Text -join '' | Should -Not -BeNullOrEmpty
                }

                It "has examples" {
                    ($help.Examples.Example | Select-Object -First 1).Code | Should -Not -BeNullOrEmpty
                }

                It "has descriptions for all examples" {
                    foreach ($example in ($help.Examples.Example)) {
                        $example.remarks.Text | Should -Not -BeNullOrEmpty
                    }
                }

                It "has at least as many examples as ParameterSets" {
                    ($help.Examples.Example | Measure-Object).Count | Should -BeGreaterOrEqual $command.ParameterSets.Count
                }

                It "has a link to the 'Online Version'" {
                    # PlatyPS 1.0 uses "Online Version" without colon, older versions used "Online Version:".
                    [Uri]$onlineLink = ($help.relatedLinks.navigationLink | Where-Object { $_.linkText -match "^Online Version:?$" }).Uri

                    $onlineLink.Authority | Should -Be "atlassianps.org"
                    $onlineLink.Scheme | Should -Be "https"
                    $onlineLink.PathAndQuery | Should -Be "/docs/JiraAgilePS/commands/$sourceCommandName/"
                }

                It "does not list Object[] / System.Object[] as a pipeline INPUT type" {
                    $inputNames = @($help.inputTypes.inputType) | Where-Object { $_ } | ForEach-Object {
                        if ($_.type -and $_.type.name) { ($_.type.name -as [String]).Trim() }
                    }
                    foreach ($n in $inputNames) {
                        $n | Should -Not -Match '^(System\.)?Object\[\]$' -Because "Object[] / System.Object[] in INPUTS is PlatyPS introspection noise from Object[] parameters tagged with [PSTypeName('JiraPS.X')]; use the concrete type heading instead"
                    }
                }

                It "does not emit mangled input/output type names" {
                    $typeNames = @(
                        @($help.inputTypes.inputType) +
                        @($help.returnValues.returnValue)
                    ) | Where-Object { $_ } | ForEach-Object {
                        if ($_.type -and $_.type.name) { ($_.type.name -as [String]).Trim() }
                    }
                    foreach ($typeName in $typeNames) {
                        if ([string]::IsNullOrEmpty($typeName)) { continue }
                        $typeName | Should -Not -Match '^[\[\]]$' -Because "type names should never be a stray bracket character"
                        $typeName.Length | Should -BeGreaterThan 1 -Because "single-character type names indicate a parser regression in INPUTS/OUTPUTS"
                        $typeName | Should -Not -Match '^Markdig\.' -Because "Markdig parser internals must never appear as type names; check the markdown heading for malformed brackets"
                        $typeName | Should -Not -Match '^<' -Because "legacy '<TODO>' placeholder headings must be replaced with real type names"
                    }
                }
            }

            Context "Parameter for <_.CommandName>" -Skip:(-not $isRunningInReleaseFolder) {
                BeforeAll {
                    $script:publicParameters = @(
                        foreach ($paramName in $command.Parameters.Keys) {
                            if ($paramName -in $DefaultParams) { continue }
                            $paramAttr = $command.Parameters[$paramName].Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
                            if ($paramAttr.DontShow -contains $true) { continue }
                            $paramName
                        }
                    )

                    $helpParametersByName = @{}
                    foreach ($helpParameter in @($help.Parameters.Parameter)) {
                        if ($helpParameter -and $helpParameter.Name) {
                            $helpParametersByName[$helpParameter.Name] = $helpParameter
                        }
                    }

                    $script:canValidateMandatoryFlag = $true
                    $mandatoryParameters = @(
                        foreach ($paramName in $publicParameters) {
                            if ($command.Parameters[$paramName].ParameterSets.Values.IsMandatory -contains "True") {
                                $paramName
                            }
                        }
                    )
                    if ($mandatoryParameters.Count -gt 0) {
                        $mandatoryMarkedInHelp = $false
                        foreach ($paramName in $mandatoryParameters) {
                            if ($helpParametersByName.ContainsKey($paramName)) {
                                $requiredValue = $helpParametersByName[$paramName].Required -as [string]
                                if ($requiredValue -and $requiredValue -match '^[Tt]rue$') {
                                    $mandatoryMarkedInHelp = $true
                                    break
                                }
                            }
                        }
                        if (-not $mandatoryMarkedInHelp) {
                            $script:canValidateMandatoryFlag = $false
                        }
                    }

                    $script:canValidateParameterType = @(
                        foreach ($paramName in $publicParameters) {
                            if ($helpParametersByName.ContainsKey($paramName)) {
                                $typeValue = $helpParametersByName[$paramName].parameterValue -as [string]
                                if (-not [string]::IsNullOrWhiteSpace($typeValue)) { $typeValue }
                            }
                        }
                    ).Count -gt 0

                    $script:canValidatePipelineFlag = $true
                    $pipelineParameters = @(
                        foreach ($paramName in $publicParameters) {
                            $codeParam = $command.Parameters[$paramName]
                            $acceptsPipeline = (
                                ($codeParam.ParameterSets.Values.ValueFromPipeline -contains $true) -or
                                ($codeParam.ParameterSets.Values.ValueFromPipelineByPropertyName -contains $true)
                            )
                            if ($acceptsPipeline) { $paramName }
                        }
                    )
                    if ($pipelineParameters.Count -gt 0) {
                        $pipelineMarkedInHelp = $false
                        foreach ($paramName in $pipelineParameters) {
                            if ($helpParametersByName.ContainsKey($paramName)) {
                                $pipelineValue = $helpParametersByName[$paramName].pipelineInput -as [string]
                                if ($pipelineValue -and $pipelineValue -match '^[Tt]rue') {
                                    $pipelineMarkedInHelp = $true
                                    break
                                }
                            }
                        }
                        if (-not $pipelineMarkedInHelp) {
                            $script:canValidatePipelineFlag = $false
                        }
                    }
                }

                Context "Parameter: <_>" -ForEach $parameters {
                    BeforeAll {
                        $script:parameterName = $_
                        $script:parameterCode = $command.Parameters[$parameterName]
                        $script:parameterHelp = $help.Parameters.Parameter | Where-Object Name -EQ $parameterName
                    }

                    It "is documented in help" {
                        $parameterHelp | Should -Not -BeNullOrEmpty
                    }

                    It "has a description" {
                        $descriptionText = if ($parameterHelp) { $parameterHelp.Description.Text }
                        $descriptionText | Should -Not -BeNullOrEmpty
                    }

                    It "has a mandatory flag" {
                        if (-not $canValidateMandatoryFlag) { return }
                        $isMandatory = $parameterCode.ParameterSets.Values.IsMandatory -contains "True"
                        $isRequiredInHelp = if ($parameterHelp) { $parameterHelp.Required }

                        $command | Should -HaveParameter $parameterName -Mandatory:$isMandatory
                        $isRequiredInHelp | Should -BeLike $isMandatory.ToString()
                    }

                    It "matches the type of the parameter in code and help" {
                        if (-not $canValidateParameterType) { return }
                        $codeType = $parameterCode.ParameterType.Name
                        if ($codeType -eq "Object" -or $codeType -eq "Object[]") {
                            $psTypeAttr = $parameterCode.Attributes | Where-Object { $_ -is [System.Management.Automation.PSTypeNameAttribute] } | Select-Object -First 1
                            if ($psTypeAttr) {
                                $codeType = $psTypeAttr.PSTypeName
                                if ($parameterCode.ParameterType.IsArray -and $codeType -notmatch '\[\]$') {
                                    $codeType += '[]'
                                }
                            }
                        }
                        $helpType = if ($parameterHelp -and $parameterHelp.parameterValue) { $parameterHelp.parameterValue.Trim() }
                        if ($helpType -eq "PSCustomObject") { $helpType = "PSObject" }
                        if ($helpType -eq "Switch") { $helpType = "SwitchParameter" }

                        $helpType | Should -Be $codeType
                    }

                    It "preserves alias metadata in help" {
                        if (-not $parameterHelp) { return }
                        $codeAliases = @($parameterCode.Aliases | Sort-Object)
                        if ($codeAliases.Count -eq 0) { return }

                        $helpAliasField = ($parameterHelp.aliases -as [String]).Trim()
                        $helpAliases = @()
                        if ($helpAliasField -and $helpAliasField -ne 'None' -and $helpAliasField -ne 'none') {
                            $helpAliases = @($helpAliasField -split '[,\s]+' | Where-Object { $_ } | Sort-Object)
                        }

                        $helpAliases | Should -Be $codeAliases -Because "every alias declared on the parameter must be reachable through Get-Help"
                    }

                    It "preserves pipeline input flag in help" {
                        if (-not $canValidatePipelineFlag) { return }
                        $byValue = $parameterCode.ParameterSets.Values.ValueFromPipeline -contains $true
                        $byProperty = $parameterCode.ParameterSets.Values.ValueFromPipelineByPropertyName -contains $true
                        $codeAcceptsPipeline = $byValue -or $byProperty

                        $helpField = if ($parameterHelp) { ($parameterHelp.pipelineInput -as [String]).Trim() }
                        $helpAcceptsPipeline = $helpField -match '^[Tt]rue'

                        $helpAcceptsPipeline | Should -Be $codeAcceptsPipeline -Because "Get-Help must reflect the actual pipeline-input behavior declared by [Parameter()]"
                    }
                }

                It "does not have parameters that are not in the code" {
                    $parameter = @()
                    if ($help.Parameters | Get-Member -Name Parameter) {
                        $parameter = $help.Parameters.Parameter.Name | Sort-Object -Unique
                    }

                    foreach ($helpParm in $parameter) {
                        $command.Parameters.Keys | Should -Contain $helpParm
                    }
                }

                It "documents every public parameter exposed by the code" {
                    $documented = @()
                    if ($help.Parameters | Get-Member -Name Parameter) {
                        $documented = @($help.Parameters.Parameter.Name)
                    }

                    foreach ($paramName in $command.Parameters.Keys) {
                        if ($paramName -in $DefaultParams) { continue }
                        $paramAttr = $command.Parameters[$paramName].Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
                        if ($paramAttr.DontShow -contains $true) { continue }

                        $documented | Should -Contain $paramName -Because "every public parameter must be documented in docs/en-US/commands/$sourceCommandName.md (or marked [Parameter(DontShow)] if it is internal)"
                    }
                }
            }
        }
    }

    Describe "About topics" -Skip:(-not $isRunningInReleaseFolder) {
        It "does not define duplicate about topic headings" {
            $duplicateTopics = @($aboutTopicDeclarations | Group-Object -Property TopicName | Where-Object { $_.Count -gt 1 })
            if ($duplicateTopics.Count -gt 0) {
                $details = @(
                    foreach ($duplicateTopic in $duplicateTopics) {
                        $sources = @($duplicateTopic.Group.SourcePath) -join "', '"
                        "$($duplicateTopic.Name): '$sources'"
                    }
                ) -join '; '
                throw "Duplicate about topic headings found: $details"
            }
        }

        It "exposes Get-Help for every documented about topic" {
            $aboutTopics | Should -Not -BeNullOrEmpty

            foreach ($topicName in $aboutTopics) {
                $topicHelp = Get-Help $topicName -ErrorAction SilentlyContinue
                $topicHelp | Should -Not -BeNullOrEmpty -Because "the markdown topic '$topicName' must be shipped as module help text"
            }
        }
    }
}
