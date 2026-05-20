---
external help file: JiraAgilePS-help.xml
Module Name: JiraAgilePS
online version: https://atlassianps.org/docs/JiraAgilePS/commands/Get-JiraAgileBacklogIssue/
locale: en-US
layout: documentation
permalink: /docs/JiraAgilePS/commands/Get-JiraAgileBacklogIssue/
---
# Get-JiraAgileBacklogIssue

## SYNOPSIS

Gets backlog issues for a Jira Agile board.

## SYNTAX

```powershell
Get-JiraAgileBacklogIssue [-Board] <Board> [[-PageSize] <UInt32>] [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

`Get-JiraAgileBacklogIssue` calls:

- `GET /rest/agile/1.0/board/{boardId}/backlog`

The command supports paging and converts issue results into JiraAgilePS issue objects.

Cloud note: this endpoint is deprecated by Atlassian Cloud; it remains part of the first-release scope for compatibility.

## EXAMPLES

### EXAMPLE 1

```powershell
$board = JiraAgilePS\Get-JiraAgileBoard -BoardId 7 -Credential $cred
JiraAgilePS\Get-JiraAgileBacklogIssue -Board $board -Credential $cred
```

Returns backlog issues for board 7.

## PARAMETERS

### -Board

Board object to query.

### -PageSize

Maximum number of issues requested per page.

### -Credential

Credentials used for Jira authentication.

## INPUTS

### AtlassianPS.JiraAgilePS.Board

## OUTPUTS

### AtlassianPS.JiraAgilePS.Issue

## RELATED LINKS

[Get-JiraAgileBoardIssue](/docs/JiraAgilePS/commands/Get-JiraAgileBoardIssue/)

[Commands index](/docs/JiraAgilePS/commands/)
