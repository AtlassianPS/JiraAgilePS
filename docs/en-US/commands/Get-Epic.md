---
external help file: JiraAgilePS-help.xml
Module Name: JiraAgilePS
online version: https://atlassianps.org/docs/JiraAgilePS/commands/Get-Epic/
locale: en-US
layout: documentation
permalink: /docs/JiraAgilePS/commands/Get-Epic/
---
# Get-JiraAgileEpic

## SYNOPSIS

Gets details for one or more Jira Agile epics.

## SYNTAX

### _ById (Default)

```powershell
Get-JiraAgileEpic [-Epic] <Epic[]> [-Credential <PSCredential>] [<CommonParameters>]
```

### _ByBoard

```powershell
Get-JiraAgileEpic [-Board] <Board> [[-PageSize] <UInt32>] [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

`Get-JiraAgileEpic` supports:

- `GET /rest/agile/1.0/epic/{epicId}`
- `GET /rest/agile/1.0/board/{boardId}/epic`

Returns JiraAgilePS epic objects for direct epic lookup or board-scoped epic listing.

## EXAMPLES

### EXAMPLE 1

```powershell
$epic = [AtlassianPS.JiraAgilePS.Epic]::new(10001)
JiraAgilePS\Get-JiraAgileEpic -Epic $epic -Credential $cred
```

Returns details for epic 10001.

### EXAMPLE 2

```powershell
$board = JiraAgilePS\Get-JiraAgileBoard -BoardId 7 -Credential $cred
JiraAgilePS\Get-JiraAgileEpic -Board $board -Credential $cred
```

Returns epics associated with board 7.

## PARAMETERS

### -Epic

One or more epic objects/identifiers to query.

### -Board

Board object used for board-scoped epic retrieval.

### -PageSize

Maximum number of epics requested per page.

### -Credential

Credentials used for Jira authentication.

## INPUTS

### AtlassianPS.JiraAgilePS.Epic

### AtlassianPS.JiraAgilePS.Board

## OUTPUTS

### AtlassianPS.JiraAgilePS.Epic

## RELATED LINKS

[Get-JiraAgileIssue](/docs/JiraAgilePS/commands/Get-JiraAgileIssue/)
