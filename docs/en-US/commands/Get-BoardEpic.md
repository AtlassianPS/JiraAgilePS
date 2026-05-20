---
external help file: JiraAgilePS-help.xml
Module Name: JiraAgilePS
online version: https://atlassianps.org/docs/JiraAgilePS/commands/Get-JiraAgileBoardEpic/
locale: en-US
layout: documentation
permalink: /docs/JiraAgilePS/commands/Get-JiraAgileBoardEpic/
---
# Get-JiraAgileBoardEpic

## SYNOPSIS

Gets epics associated with a Jira Agile board.

## SYNTAX

```powershell
Get-JiraAgileBoardEpic [-Board] <Board> [[-PageSize] <UInt32>] [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

`Get-JiraAgileBoardEpic` calls:

- `GET /rest/agile/1.0/board/{boardId}/epic`

The command supports paging and converts epic results into JiraAgilePS epic objects.

## EXAMPLES

### EXAMPLE 1

```powershell
$board = JiraAgilePS\Get-JiraAgileBoard -BoardId 7 -Credential $cred
JiraAgilePS\Get-JiraAgileBoardEpic -Board $board -Credential $cred
```

Returns epics for board 7.

## PARAMETERS

### -Board

Board object to query.

### -PageSize

Maximum number of epics requested per page.

### -Credential

Credentials used for Jira authentication.

## INPUTS

### AtlassianPS.JiraAgilePS.Board

## OUTPUTS

### AtlassianPS.JiraAgilePS.Epic

## RELATED LINKS

[Get-JiraAgileEpic](/docs/JiraAgilePS/commands/Get-JiraAgileEpic/)

[Get-JiraAgileEpicIssue](/docs/JiraAgilePS/commands/Get-JiraAgileEpicIssue/)
