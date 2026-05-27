<#
.SYNOPSIS
    Waits for the Dockerized Jira Data Center test instance to become reachable.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Diagnostic CI script writes progress banners for Actions logs.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', 'Password', Justification = 'Dockerized local Jira test fixture uses a fixed default admin password.')]
[CmdletBinding()]
param(
    [Parameter()]
    [int]$TimeoutSeconds = 1200,

    [Parameter()]
    [string]$BaseUrl = 'http://localhost:2990/jira',

    [Parameter()]
    [string]$Username = 'admin',

    [Parameter()]
    [string]$Password = 'admin'
)

$ErrorActionPreference = 'Stop'
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$serverInfoUrl = "$($BaseUrl.TrimEnd('/'))/rest/api/2/serverInfo"
$agileUrl = "$($BaseUrl.TrimEnd('/'))/rest/agile/1.0/board?maxResults=1"
$projectUrl = "$($BaseUrl.TrimEnd('/'))/rest/api/2/project"
$projectKey = 'TEST'
$authPair = "${Username}:${Password}"
$headers = @{ Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($authPair)) }

Write-Host "Waiting for Jira Data Center at $BaseUrl" -ForegroundColor Cyan
$isReachable = $false

do {
    try {
        $response = Invoke-WebRequest -Uri $serverInfoUrl -Headers $headers -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
        if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 300) {
            Write-Host 'Jira Data Center is reachable.' -ForegroundColor Green
            $isReachable = $true
            break
        }
    }
    catch {
        Write-Host "Still waiting: $($_.Exception.Message)" -ForegroundColor DarkGray
    }

    Start-Sleep -Seconds 10
} while ((Get-Date) -lt $deadline)

if (-not $isReachable) {
    throw "Timed out after $TimeoutSeconds seconds waiting for Jira Data Center at $BaseUrl."
}

try {
    $response = Invoke-WebRequest -Uri $agileUrl -Headers $headers -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop
    if ($response.StatusCode -lt 200 -or $response.StatusCode -ge 300) {
        throw "Unexpected status code $($response.StatusCode)."
    }
}
catch {
    throw "Jira Data Center is reachable, but Jira Software Agile REST is not available at $agileUrl. The Docker image is not valid for JiraAgilePS integration coverage. $($_.Exception.Message)"
}

try {
    $null = Invoke-WebRequest -Uri "$projectUrl/$projectKey" -Headers $headers -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop
    Write-Host "Jira Data Center test project '$projectKey' is available." -ForegroundColor Green
    return
}
catch {
    Write-Host "Provisioning Jira Data Center test project '$projectKey'." -ForegroundColor Cyan
}

$projectBody = @{
    name               = 'Test'
    key                = $projectKey
    projectTypeKey     = 'software'
    projectTemplateKey = 'com.pyxis.greenhopper.jira:gh-scrum-template'
    lead               = $Username
    assigneeType       = 'PROJECT_LEAD'
} | ConvertTo-Json -Compress

try {
    $null = Invoke-WebRequest -Uri $projectUrl -Method Post -Headers $headers -ContentType 'application/json' -Body $projectBody -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop
    Write-Host "Jira Data Center test project '$projectKey' was provisioned." -ForegroundColor Green
}
catch {
    throw "Jira Data Center is reachable, but test project '$projectKey' could not be provisioned. $($_.Exception.Message)"
}
