---
external help file: JiraAgilePS-help.xml
Module Name: JiraAgilePS
online version: https://atlassianps.org/docs/JiraAgilePS/commands/Get-JiraAgileIssue/
locale: en-US
layout: documentation
permalink: /docs/JiraAgilePS/commands/Get-JiraAgileIssue/
---
# Get-JiraAgileIssue

## SYNOPSIS

Gets Jira Agile issues with board, backlog, or sprint scope.

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

## DESCRIPTION

`Get-JiraAgileIssue` consolidates Jira Agile issue retrieval endpoints:

- `GET /rest/agile/1.0/board/{boardId}/issue` (board scope)
- `GET /rest/agile/1.0/board/{boardId}/backlog` (backlog scope)
- `GET /rest/agile/1.0/board/{boardId}/sprint/{sprintId}/issue` (sprint scope)

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

## PARAMETERS

### -Board

Board object to query.

### -Backlog

Switch to retrieve backlog issues for the specified board.

### -Sprint

One or more sprint objects to retrieve sprint-scoped issues.

### -PageSize

Maximum number of issues requested per page.

### -Credential

Credentials used for Jira authentication.

## INPUTS

### AtlassianPS.JiraAgilePS.Board

### AtlassianPS.JiraAgilePS.Sprint

## OUTPUTS

### AtlassianPS.JiraAgilePS.Issue

## RELATED LINKS

[Get-JiraAgileBoardConfiguration](/docs/JiraAgilePS/commands/Get-JiraAgileBoardConfiguration/)

[Get-JiraAgileEpicIssue](/docs/JiraAgilePS/commands/Get-JiraAgileEpicIssue/)
