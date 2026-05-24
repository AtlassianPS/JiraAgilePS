<#
.SYNOPSIS
    Waits for the Dockerized Jira Data Center test instance to become reachable.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Diagnostic CI script writes progress banners for Actions logs.')]
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
