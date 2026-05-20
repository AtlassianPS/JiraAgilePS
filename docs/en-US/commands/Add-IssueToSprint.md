---
external help file: JiraAgilePS-help.xml
Module Name: JiraAgilePS
online version: https://atlassianps.org/docs/JiraAgilePS/commands/Add-IssueToSprint/
locale: en-US
layout: documentation
permalink: /docs/JiraAgilePS/commands/Add-IssueToSprint/
---
# Add-IssueToSprint

## SYNOPSIS

Adds one or more Jira issues to a sprint.

## SYNTAX

```powershell
Add-IssueToSprint [-Issue] <Object> [-Sprint] <Sprint> [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

`Add-IssueToSprint` assigns Jira issues to a target sprint.

If the supplied sprint object is incomplete, the command resolves it first and then submits issue keys in request batches.

## EXAMPLES

### EXAMPLE 1

```powershell
$board  = JiraAgilePS\Get-Board -Credential $cred | Select-Object -First 1
$sprint = JiraAgilePS\Get-Sprint -Board $board -State Active -Credential $cred | Select-Object -First 1
$issue  = Get-JiraIssue -Issue "PROJ-123" -Credential $cred

JiraAgilePS\Add-IssueToSprint -Issue $issue -Sprint $sprint -Credential $cred
```

Adds one Jira issue to the active sprint.

### EXAMPLE 2

```powershell
$issues = @(
    Get-JiraIssue -Issue "PROJ-123" -Credential $cred
    Get-JiraIssue -Issue "PROJ-124" -Credential $cred
)

JiraAgilePS\Add-IssueToSprint -Issue $issues -Sprint $sprint -Credential $cred
```

Adds multiple issues to a sprint.

## PARAMETERS

### -Issue

Issue object(s) to add to the sprint.

### -Sprint

Target sprint object.

### -Credential

Credentials used for Jira authentication.

## INPUTS

### System.Object

Issue object(s) from JiraPS commands, for example `Get-JiraIssue`.

## OUTPUTS

### System.Void

## NOTES

This command does not emit output on success.

## RELATED LINKS

[Get-Board](Get-Board.html)

[Get-Sprint](Get-Sprint.html)
