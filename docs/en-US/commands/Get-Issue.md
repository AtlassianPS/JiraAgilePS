---
external help file: JiraAgilePS-help.xml
Module Name: JiraAgilePS
online version: https://atlassianps.org/docs/JiraAgilePS/commands/Get-Issue/
locale: en-US
layout: documentation
permalink: /docs/JiraAgilePS/commands/Get-Issue/
---
# Get-JiraAgileIssue

## SYNOPSIS

Gets Jira Agile issues across board, backlog, sprint, and epic scopes.

## SYNTAX

### _Board (Default)

```powershell
Get-JiraAgileIssue [-Board] <Board> [[-PageSize] <UInt32>] [-Credential <PSCredential>] [<CommonParameters>]
```

### _Backlog

```powershell
Get-JiraAgileIssue [-Board] <Board> -Backlog [[-PageSize] <UInt32>] [-Credential <PSCredential>] [<CommonParameters>]
```

### _Sprint

```powershell
Get-JiraAgileIssue [-Board] <Board> [-Sprint] <Sprint[]> [[-PageSize] <UInt32>] [-Credential <PSCredential>] [<CommonParameters>]
```

### _Epic

```powershell
Get-JiraAgileIssue [-Epic] <Epic[]> [[-PageSize] <UInt32>] [-Credential <PSCredential>] [<CommonParameters>]
```

### _BoardEpic

```powershell
Get-JiraAgileIssue [-Board] <Board> [-Epic] <Epic[]> [[-PageSize] <UInt32>] [-Credential <PSCredential>] [<CommonParameters>]
```

### _BoardWithoutEpic

```powershell
Get-JiraAgileIssue [-Board] <Board> -WithoutEpic [[-PageSize] <UInt32>] [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

`Get-JiraAgileIssue` consolidates Jira Agile issue retrieval endpoints:

- `GET /rest/agile/1.0/board/{boardId}/issue` (board scope)
- `GET /rest/agile/1.0/board/{boardId}/backlog` (backlog scope)
- `GET /rest/agile/1.0/board/{boardId}/sprint/{sprintId}/issue` (sprint scope)
- `GET /rest/agile/1.0/epic/{epicId}/issue` (epic scope)
- `GET /rest/agile/1.0/board/{boardId}/epic/{epicId}/issue` (board + epic scope)
- `GET /rest/agile/1.0/board/{boardId}/epic/none/issue` (board issues with no epic)

The command supports paging and converts issue results into JiraAgilePS issue objects.

## EXAMPLES

### EXAMPLE 1

```powershell
$board = JiraAgilePS\Get-JiraAgileBoard -BoardId 7 -Credential $cred
JiraAgilePS\Get-JiraAgileIssue -Board $board -Credential $cred
```

Returns issues visible on board 7.

### EXAMPLE 2

```powershell
$board = JiraAgilePS\Get-JiraAgileBoard -BoardId 7 -Credential $cred
JiraAgilePS\Get-JiraAgileIssue -Board $board -Backlog -Credential $cred
```

Returns backlog issues for board 7.

### EXAMPLE 3

```powershell
$board = JiraAgilePS\Get-JiraAgileBoard -BoardId 7 -Credential $cred
$sprint = JiraAgilePS\Get-JiraAgileSprint -Board $board -State Active -Credential $cred | Select-Object -First 1
JiraAgilePS\Get-JiraAgileIssue -Board $board -Sprint $sprint -Credential $cred
```

Returns issues for the active sprint.

### EXAMPLE 4

```powershell
$epic = [AtlassianPS.JiraAgilePS.Epic]::new(10001)
JiraAgilePS\Get-JiraAgileIssue -Epic $epic -Credential $cred
```

Returns issues for epic 10001.

### EXAMPLE 5

```powershell
$board = JiraAgilePS\Get-JiraAgileBoard -BoardId 7 -Credential $cred
$epic = [AtlassianPS.JiraAgilePS.Epic]::new(10001)
JiraAgilePS\Get-JiraAgileIssue -Board $board -Epic $epic -Credential $cred
```

Returns board-scoped issues for the epic.

### EXAMPLE 6

```powershell
$board = JiraAgilePS\Get-JiraAgileBoard -BoardId 7 -Credential $cred
JiraAgilePS\Get-JiraAgileIssue -Board $board -WithoutEpic -Credential $cred
```

Returns board issues that are not assigned to an epic.

## PARAMETERS

### -Board

Board object to query.

### -Backlog

Switch to retrieve backlog issues for the specified board.

### -Sprint

One or more sprint objects to retrieve sprint-scoped issues.

### -Epic

One or more epic objects/identifiers to retrieve epic-scoped issues.

### -WithoutEpic

Switch to retrieve board issues that have no epic assignment.

### -PageSize

Maximum number of issues requested per page.

### -Credential

Credentials used for Jira authentication.

## INPUTS

### AtlassianPS.JiraAgilePS.Board

### AtlassianPS.JiraAgilePS.Sprint

### AtlassianPS.JiraAgilePS.Epic

## OUTPUTS

### AtlassianPS.JiraAgilePS.Issue

## RELATED LINKS

[Get-JiraAgileBoardConfiguration](/docs/JiraAgilePS/commands/Get-JiraAgileBoardConfiguration/)

[Get-JiraAgileEpic](/docs/JiraAgilePS/commands/Get-JiraAgileEpic/)
