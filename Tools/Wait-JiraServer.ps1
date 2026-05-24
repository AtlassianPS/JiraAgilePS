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
$boardUrl = "$($BaseUrl.TrimEnd('/'))/rest/agile/1.0/board?maxResults=1"
$authPair = "${Username}:${Password}"
$headers = @{ Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($authPair)) }

Write-Host "Waiting for Jira Data Center at $BaseUrl" -ForegroundColor Cyan

do {
    try {
        $response = Invoke-WebRequest -Uri $boardUrl -Headers $headers -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
        if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 300) {
            Write-Host 'Jira Data Center Agile API is reachable.' -ForegroundColor Green
            return
        }
    }
    catch {
        Write-Host "Still waiting: $($_.Exception.Message)" -ForegroundColor DarkGray
    }

    Start-Sleep -Seconds 10
} while ((Get-Date) -lt $deadline)

throw "Timed out after $TimeoutSeconds seconds waiting for Jira Data Center at $BaseUrl."
