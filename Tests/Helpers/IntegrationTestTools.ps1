. "$PSScriptRoot/TestTools.ps1"

$script:TestResourcePrefix = 'JiraAgilePS-IntTest-'
$script:_CachedIntegrationEnv = $null
$script:_EnvLoaded = $false
$script:_CleanupInProgress = $false

function Read-DotEnvFile {
    <#
    .SYNOPSIS
        Loads KEY=value pairs from a .env file into the current process environment.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Reading a .env file into process env vars is intentional and idempotent')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    Get-Content -LiteralPath $Path | ForEach-Object {
        $line = $_
        if ($line -match '^\s*#' -or $line -match '^\s*$') { return }
        if ($line -notmatch '^\s*([^#=]+?)\s*=\s*(.*)$') { return }

        $name = $matches[1].Trim()
        if ([string]::IsNullOrEmpty($name)) { return }

        $rawValue = $matches[2].TrimStart()

        if ($rawValue.Length -gt 0 -and ($rawValue[0] -eq '"' -or $rawValue[0] -eq "'")) {
            $quote = $rawValue[0]
            $endIdx = $rawValue.IndexOf($quote, 1)
            $value = if ($endIdx -gt 0) {
                $rawValue.Substring(1, $endIdx - 1)
            }
            else {
                $rawValue.Substring(1)
            }
        }
        else {
            if ($rawValue -match '^(.*?)\s+#') {
                $value = $matches[1]
            }
            else {
                $value = $rawValue
            }
            $value = $value.TrimEnd()
        }

        [System.Environment]::SetEnvironmentVariable($name, $value)
    }
}

function Initialize-IntegrationEnvironment {
    <#
    .SYNOPSIS
        Loads and validates integration test environment configuration.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Process-wide warn-once flag; a script-scoped flag resets every time Pester dot-sources this file from BeforeDiscovery.')]
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    if ($script:_EnvLoaded) {
        return $script:_CachedIntegrationEnv
    }

    $projectRoot = Resolve-ProjectRoot

    $envFile = Join-Path $projectRoot '.env'
    if (Test-Path $envFile) {
        Read-DotEnvFile -Path $envFile
        Write-Verbose "Loaded environment from: $envFile"
    }

    $deploymentType = if ($env:CI_JIRA_TYPE) { $env:CI_JIRA_TYPE } else { 'Cloud' }
    if ($deploymentType -notin @('Cloud', 'Server')) {
        throw "Invalid CI_JIRA_TYPE '$deploymentType'. Must be 'Cloud' or 'Server'."
    }

    $requiredVars = if ($deploymentType -eq 'Server') {
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

    $missing = @()
    foreach ($var in $requiredVars) {
        if ([string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable($var))) {
            $missing += $var
        }
    }

    if ($missing.Count -gt 0) {
        $warnedFlag = Get-Variable -Name _JiraAgilePSIntegrationEnvWarned -Scope Global -ErrorAction SilentlyContinue
        if (-not $warnedFlag -or -not [bool]$warnedFlag.Value) {
            Write-Warning "Integration tests ($deploymentType track) require the following environment variables: $($missing -join ', ')"
            if ($deploymentType -eq 'Server') {
                Write-Warning "Set CI_JIRA_TYPE=Server and the CI_JIRA_* vars (defaults match the moveworkforward/atlas-run-standalone Docker image). See .env.example."
            }
            else {
                Write-Warning "Copy .env.example to .env and configure your Jira Cloud connection."
            }
            $global:_JiraAgilePSIntegrationEnvWarned = $true
        }
        $script:_EnvLoaded = $true
        $script:_CachedIntegrationEnv = $null
        return $null
    }

    if ($deploymentType -eq 'Server') {
        $result = [PSCustomObject]@{
            DeploymentType = 'Server'
            IsCloud        = $false
            UserIdProperty = 'name'
            CloudUrl       = $env:CI_JIRA_URL.TrimEnd('/')
            Username       = $env:CI_JIRA_ADMIN
            Password       = $env:CI_JIRA_ADMIN_PASSWORD
            UsernameNormal = $env:CI_JIRA_USER
            PasswordNormal = $env:CI_JIRA_USER_PASSWORD
            HasNormalUser  = -not [string]::IsNullOrEmpty($env:CI_JIRA_USER)
            TestProject    = if ($env:JIRA_TEST_PROJECT) { $env:JIRA_TEST_PROJECT } else { 'TEST' }
            TestIssue      = $env:JIRA_TEST_ISSUE
            TestUser       = $env:CI_JIRA_USER
            TestGroup      = $env:JIRA_TEST_GROUP
            TestFilter     = $env:JIRA_TEST_FILTER
            TestVersion    = $env:JIRA_TEST_VERSION
            ReadOnly       = $env:JIRA_TEST_READONLY -eq 'true'
            VerboseOutput  = $env:JIRA_TEST_VERBOSE -eq 'true'
        }
    }
    else {
        $result = [PSCustomObject]@{
            DeploymentType = 'Cloud'
            IsCloud        = $true
            UserIdProperty = 'accountId'
            CloudUrl       = $env:JIRA_CLOUD_URL.TrimEnd('/')
            Username       = $env:JIRA_CLOUD_USERNAME
            Password       = $env:JIRA_CLOUD_PASSWORD
            UsernameNormal = $env:JIRA_CLOUD_USERNAME_NORMAL
            PasswordNormal = $env:JIRA_CLOUD_PASSWORD_NORMAL
            HasNormalUser  = (-not [string]::IsNullOrEmpty($env:JIRA_CLOUD_USERNAME_NORMAL)) -and
            (-not [string]::IsNullOrEmpty($env:JIRA_CLOUD_PASSWORD_NORMAL))
            TestProject    = $env:JIRA_TEST_PROJECT
            TestIssue      = $env:JIRA_TEST_ISSUE
            TestUser       = $env:JIRA_TEST_USER
            TestGroup      = $env:JIRA_TEST_GROUP
            TestFilter     = $env:JIRA_TEST_FILTER
            TestVersion    = $env:JIRA_TEST_VERSION
            ReadOnly       = $env:JIRA_TEST_READONLY -eq 'true'
            VerboseOutput  = $env:JIRA_TEST_VERBOSE -eq 'true'
        }
    }

    $script:_EnvLoaded = $true
    $script:_CachedIntegrationEnv = $result
    return $result
}

function Connect-JiraTestServer {
    <#
    .SYNOPSIS
        Establishes an authenticated session with the test Jira instance.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Test helper requires plaintext conversion for API token from environment')]
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [PSCustomObject]$Environment
    )

    if (-not $Environment) {
        $Environment = Initialize-IntegrationEnvironment
        if (-not $Environment) {
            throw "Integration environment not configured. See .env.example for required variables."
        }
    }

    $currentServer = Get-JiraConfigServer -ErrorAction SilentlyContinue
    if (-not $currentServer -or $currentServer.ToString().TrimEnd('/') -ne $Environment.CloudUrl) {
        Set-JiraConfigServer -Server $Environment.CloudUrl
    }

    if ($Environment.IsCloud) {
        $authPair = "$($Environment.Username):$($Environment.Password)"
        $basicAuthHeader = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($authPair))
        $session = New-JiraSession -Headers @{ Authorization = $basicAuthHeader }
        if (-not $session) {
            throw "Failed to establish Jira session. Check credentials and server URL. For Jira Cloud, JIRA_CLOUD_PASSWORD must be an API token (not your account password)."
        }
        Write-Verbose "Connected to Jira Cloud: $($Environment.CloudUrl)"
    }
    else {
        $authPair = "$($Environment.Username):$($Environment.Password)"
        $basicAuthHeader = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($authPair))
        $session = New-JiraSession -Headers @{ Authorization = $basicAuthHeader }
        if (-not $session) {
            throw "Failed to establish Jira session. Check credentials and server URL. For Jira Data Center, CI_JIRA_ADMIN_PASSWORD must be the admin user's password (default: 'admin' for the moveworkforward/atlas-run-standalone image)."
        }
        Write-Verbose "Connected to Jira Data Center: $($Environment.CloudUrl)"
    }

    if (-not $Environment.ReadOnly) {
        try {
            Remove-StaleTestResource -Fixtures (Get-TestFixture -Environment $Environment) -ErrorAction SilentlyContinue
        }
        catch {
            Write-Warning "Stale resource cleanup encountered an error (non-fatal): $_"
        }
    }

    return $session
}

function Get-TestFixture {
    <#
    .SYNOPSIS
        Returns a hashtable of test fixture references.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter()]
        [PSCustomObject]$Environment
    )

    if (-not $Environment) {
        $Environment = Initialize-IntegrationEnvironment
        if (-not $Environment) {
            throw "Integration environment not configured. See .env.example for required variables."
        }
    }

    @{
        TestProject    = $Environment.TestProject
        TestIssue      = $Environment.TestIssue
        TestUser       = $Environment.TestUser
        TestGroup      = $Environment.TestGroup
        TestFilter     = $Environment.TestFilter
        TestVersion    = $Environment.TestVersion
        CloudUrl       = $Environment.CloudUrl
        ReadOnly       = $Environment.ReadOnly
        DeploymentType = $Environment.DeploymentType
        IsCloud        = $Environment.IsCloud
        UserIdProperty = $Environment.UserIdProperty
    }
}

function Skip-IntegrationTest {
    <#
    .SYNOPSIS
        Determines whether integration tests should be skipped.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $config = Initialize-IntegrationEnvironment -ErrorAction SilentlyContinue
    return ($null -eq $config)
}

function New-TemporaryTestIssue {
    <#
    .SYNOPSIS
        Creates a temporary test issue for write tests.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test helper for creating test data does not require confirmation')]
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [string]$Summary,

        [Parameter()]
        [hashtable]$Fixtures,

        [Parameter()]
        [string]$IssueType = 'Task'
    )

    if (-not $Fixtures) {
        $Fixtures = Get-TestFixture
    }

    if ($Fixtures.ReadOnly) {
        throw "Cannot create test issues in read-only mode. Set JIRA_TEST_READONLY=false in .env"
    }

    if ([string]::IsNullOrEmpty($Fixtures.TestProject)) {
        throw "Cannot create test issue without a configured test project (Fixtures.TestProject is empty)."
    }

    if ([string]::IsNullOrEmpty($Summary)) {
        $Summary = New-TestResourceName -Type 'Issue'
    }

    $issueParams = @{
        Project     = $Fixtures.TestProject
        IssueType   = $IssueType
        Summary     = $Summary
        Description = "Temporary test issue created by JiraAgilePS integration tests. Safe to delete."
    }

    $extras = Get-MinimumValidIssueParameter -Fixtures $Fixtures -IssueType $IssueType -SkipFieldId @('description')
    if ($extras.Reporter) { $issueParams.Reporter = $extras.Reporter }
    if ($extras.Fields -and $extras.Fields.Count -gt 0) { $issueParams.Fields = $extras.Fields }

    $issue = New-JiraIssue @issueParams
    Write-Verbose "Created temporary test issue: $($issue.Key)"
    return $issue
}

function Get-MinimumValidIssueParameter {
    <#
    .SYNOPSIS
        Resolves required create-issue extras from createmeta.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter()]
        [hashtable]$Fixtures,

        [Parameter()]
        [string]$IssueType = 'Task',

        [Parameter()]
        [string[]]$SkipFieldId = @()
    )

    if (-not $Fixtures) { $Fixtures = Get-TestFixture }

    $result = @{ Reporter = $null; Fields = @{} }

    if ([string]::IsNullOrEmpty($Fixtures.TestProject)) { return $result }

    try {
        $createmeta = Get-JiraIssueCreateMetadata -Project $Fixtures.TestProject -IssueType $IssueType -ErrorAction Stop -Debug:$false
    }
    catch {
        Write-Warning "Get-MinimumValidIssueParameter: createmeta probe for project [$($Fixtures.TestProject)] / issuetype [$IssueType] failed ($($_.Exception.Message)); returning empty extras. Jira may still reject the create call if the project tightens any required-no-default field."
        return $result
    }

    $userCandidate = if ($Fixtures.TestUser) {
        $Fixtures.TestUser
    }
    elseif ($env:CI_JIRA_USER) {
        $env:CI_JIRA_USER
    }
    else {
        $env:CI_JIRA_ADMIN
    }

    $alwaysProvidedById = @('project', 'issuetype', 'summary') + @($SkipFieldId | Where-Object { $_ })

    foreach ($field in @($createmeta)) {
        if (-not $field.Required) { continue }
        if ($field.HasDefaultValue) { continue }
        if ($field.Id -in $alwaysProvidedById) { continue }

        if ($field.Id -eq 'reporter' -and $userCandidate) {
            $result.Reporter = $userCandidate
            continue
        }
        if ($field.Id -eq 'assignee' -and $userCandidate) {
            $result.Fields['assignee'] = @{ name = "$userCandidate" }
            continue
        }

        $allowed = @($field.AllowedValues)
        if ($allowed.Count -gt 0) {
            $first = $allowed[0]
            $result.Fields[$field.Id] = if ($first.id) { @{ id = "$($first.id)" } } else { @{ name = "$($first.name)" } }
            continue
        }

        switch ($field.Schema.type) {
            'string' { $result.Fields[$field.Id] = "JiraAgilePS-IntTest default for $($field.Name)"; break }
            'number' { $result.Fields[$field.Id] = 0; break }
            'array' { $result.Fields[$field.Id] = @(); break }
            'user' {
                if ($userCandidate) {
                    $result.Fields[$field.Id] = @{ name = "$userCandidate" }
                }
                else {
                    Write-Warning "Get-MinimumValidIssueParameter: required user field [$($field.Name)] (id=[$($field.Id)]) cannot be defaulted because no test user is configured."
                }
                break
            }
            default {
                Write-Warning "Get-MinimumValidIssueParameter: required field [$($field.Name)] (id=[$($field.Id)], type=[$($field.Schema.type)]) has no AllowedValues, no HasDefaultValue, and no schema-derived default; New-JiraIssue may still reject the create call. Extend Get-MinimumValidIssueParameter in Tests/Helpers/IntegrationTestTools.ps1 to handle this field type."
            }
        }
    }

    return $result
}

function Remove-StaleTestResource {
    <#
    .SYNOPSIS
        Cleans up stale test resources from previous test runs.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test helper for cleanup does not require confirmation')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable]$Fixtures,

        [Parameter()]
        [TimeSpan]$MaxAge = (New-TimeSpan -Hours 1),

        [Parameter()]
        [switch]$Force
    )

    if ($script:_CleanupInProgress -and -not $Force) {
        Write-Verbose "Cleanup already performed or in progress - skipping"
        return
    }
    $script:_CleanupInProgress = $true

    if (-not $Fixtures) {
        $Fixtures = Get-TestFixture
    }

    if ($Fixtures.ReadOnly) {
        Write-Verbose "Read-only mode: skipping stale resource cleanup"
        return
    }

    $cutoffTime = (Get-Date).Add(-$MaxAge)
    $prefix = $script:TestResourcePrefix
    Write-Verbose "Cleaning up test resources older than $cutoffTime with prefix '$prefix'"

    try {
        # Quote the prefix as a phrase so Jira's text search does not tokenize on '-'
        # (which would match any of "JiraAgilePS", "IntTest" individually).
        $jql = "project = $($Fixtures.TestProject) AND summary ~ ""\""$prefix\"""" ORDER BY created ASC"
        $staleIssues = Get-JiraIssue -Query $jql -ErrorAction SilentlyContinue
        foreach ($issue in $staleIssues) {
            if ($issue.Created -lt $cutoffTime) {
                Write-Verbose "Removing stale test issue: $($issue.Key) (created $($issue.Created))"
                Remove-JiraIssue -IssueId $issue.Key -Force -ErrorAction SilentlyContinue
            }
        }
    }
    catch {
        Write-Warning "Failed to clean up stale issues: $_"
    }

    try {
        $versions = Get-JiraVersion -Project $Fixtures.TestProject -ErrorAction SilentlyContinue
        foreach ($version in $versions) {
            if ($version.Name -like "$prefix*") {
                Write-Verbose "Removing stale test version: $($version.Name)"
                Remove-JiraVersion -Version $version -Force -ErrorAction SilentlyContinue
            }
        }
    }
    catch {
        Write-Warning "Failed to clean up stale versions: $_"
    }

    try {
        $filters = Find-JiraFilter -Name $prefix -ErrorAction SilentlyContinue
        foreach ($filter in $filters) {
            if ($filter.Name -like "$prefix*") {
                Write-Verbose "Removing stale test filter: $($filter.Name)"
                Remove-JiraFilter -InputObject $filter -ErrorAction SilentlyContinue -Confirm:$false
            }
        }
    }
    catch {
        Write-Warning "Failed to clean up stale filters: $_"
    }
}

function Get-TestResourcePrefix {
    <#
    .SYNOPSIS
        Returns the prefix used for test resources.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return $script:TestResourcePrefix
}

function New-TestResourceName {
    <#
    .SYNOPSIS
        Generates a unique name for a test resource with the standard prefix.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Function only generates a string, does not modify state')]
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Type
    )

    $guidSuffix = [Guid]::NewGuid().ToString('N').Substring(0, 6)
    return "$($script:TestResourcePrefix)$Type-$(Get-Date -Format 'yyyyMMddHHmmss')-$guidSuffix"
}
