---
Module Name: JiraAgilePS
online version: https://atlassianps.org/docs/JiraAgilePS/
locale: en-US
layout: documentation
permalink: /docs/JiraAgilePS/
hide: true
---
# JiraAgilePS

## about_JiraAgilePS

# SHORT DESCRIPTION

JiraAgilePS extends JiraPS with Atlassian Jira Agile board and sprint operations.

# LONG DESCRIPTION

Use JiraAgilePS when you need to automate board and sprint workflows from PowerShell.
It relies on JiraPS connectivity and session configuration, then adds Agile-specific commands.

The module currently includes:

- `Get-Board`
- `Get-Sprint`
- `Add-IssueToSprint`

## GETTING STARTED

```powershell
Import-Module JiraPS
Import-Module JiraAgilePS

Set-JiraConfigServer "https://yourcompany.atlassian.net"
$cred = Get-Credential
New-JiraSession -Credential $cred

JiraAgilePS\Get-Board -Credential $cred
```

## SEE ALSO

- [Get-Board](commands/Get-Board.html)
- [Get-Sprint](commands/Get-Sprint.html)
- [Add-IssueToSprint](commands/Add-IssueToSprint.html)
- [Source repository](https://github.com/AtlassianPS/JiraAgilePS)
