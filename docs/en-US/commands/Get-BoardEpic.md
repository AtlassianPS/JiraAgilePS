---
external help file: JiraAgilePS-help.xml
Module Name: JiraAgilePS
online version: https://atlassianps.org/docs/JiraAgilePS/commands/Get-BoardEpic/
locale: en-US
layout: documentation
permalink: /docs/JiraAgilePS/commands/Get-BoardEpic/
---
# Get-BoardEpic

## SYNOPSIS

Gets epics associated with a Jira Agile board.

## SYNTAX

```powershell
Get-BoardEpic [-Board] <Board> [[-PageSize] <UInt32>] [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

`Get-BoardEpic` calls:

- `GET /rest/agile/1.0/board/{boardId}/epic`

The command supports paging and converts epic results into JiraAgilePS epic objects.

## EXAMPLES

### EXAMPLE 1

```powershell
$board = JiraAgilePS\Get-Board -BoardId 7 -Credential $cred
JiraAgilePS\Get-BoardEpic -Board $board -Credential $cred
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

[Get-Epic](Get-Epic.html)

[Get-EpicIssue](Get-EpicIssue.html)
