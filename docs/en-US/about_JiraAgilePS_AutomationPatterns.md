---
locale: en-US
layout: documentation
online version: https://atlassianps.org/docs/JiraAgilePS/about/automation-patterns.html
Module Name: JiraAgilePS
permalink: /docs/JiraAgilePS/about/automation-patterns.html
---
# Automation Patterns

## about_JiraAgilePS_AutomationPatterns

# SHORT DESCRIPTION

Practical scripting patterns for repeatable board/sprint automation.

# LONG DESCRIPTION

## Add all issues from a JQL query to the active sprint

```powershell
$board = JiraAgilePS\Get-Board -BoardId 42 -Credential $cred
$activeSprint = JiraAgilePS\Get-Sprint -Board $board -State Active -Credential $cred | Select-Object -First 1
$issues = Get-JiraIssue -Query 'project = APP AND status = "Selected for Development"' -Credential $cred

JiraAgilePS\Add-IssueToSprint -Issue $issues -Sprint $activeSprint -Credential $cred
```

## Resolve sprint context once, then pipeline issues

```powershell
$sprint = JiraAgilePS\Get-Sprint -Board $board -State Active -Credential $cred | Select-Object -First 1
Get-JiraIssue -Query 'project = APP AND labels = automation' -Credential $cred |
    JiraAgilePS\Add-IssueToSprint -Sprint $sprint -Credential $cred
```

## Defensive checks

Before mutating sprint assignments, validate assumptions:

```powershell
if (-not $board) { throw "Board not found." }
if (-not $sprint) { throw "No matching sprint found." }
if (-not $issues) { throw "No issues matched the query." }
```

# SEE ALSO

- [Get-Board](commands/Get-Board.html)
- [Get-Sprint](commands/Get-Sprint.html)
- [Get-JiraIssue](https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssue/)
