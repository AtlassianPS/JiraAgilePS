---
external help file: JiraAgilePS-help.xml
Module Name: JiraAgilePS
online version: https://atlassianps.org/docs/JiraAgilePS/commands/Get-JiraAgileSprintIssue/
locale: en-US
layout: documentation
permalink: /docs/JiraAgilePS/commands/Get-JiraAgileSprintIssue/
---
# Get-JiraAgileSprintIssue

## SYNOPSIS

Gets issues for one or more sprints on a Jira Agile board.

## SYNTAX

```powershell
Get-JiraAgileSprintIssue [-Board] <Board> [-Sprint] <Sprint[]> [[-PageSize] <UInt32>] [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

`Get-JiraAgileSprintIssue` calls:

- `GET /rest/agile/1.0/board/{boardId}/sprint/{sprintId}/issue`

The command supports paging and converts issue results into JiraAgilePS issue objects.

## EXAMPLES

### EXAMPLE 1

```powershell
$board = JiraAgilePS\Get-JiraAgileBoard -BoardId 7 -Credential $cred
$sprint = JiraAgilePS\Get-JiraAgileSprint -Board $board -State Active -Credential $cred | Select-Object -First 1
JiraAgilePS\Get-JiraAgileSprintIssue -Board $board -Sprint $sprint -Credential $cred
```

Returns issues for the active sprint.

## PARAMETERS

### -Board

Board object that owns the sprint.

### -Sprint

One or more sprint objects to query.

### -PageSize

Maximum number of issues requested per page.

### -Credential

Credentials used for Jira authentication.

## INPUTS

### AtlassianPS.JiraAgilePS.Sprint

## OUTPUTS

### AtlassianPS.JiraAgilePS.Issue

## RELATED LINKS

[Get-JiraAgileBoardIssue](/docs/JiraAgilePS/commands/Get-JiraAgileBoardIssue/)

[Commands index](/docs/JiraAgilePS/commands/)
