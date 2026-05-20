---
external help file: JiraAgilePS-help.xml
Module Name: JiraAgilePS
online version: https://atlassianps.org/docs/JiraAgilePS/commands/Get-EpicIssue/
locale: en-US
layout: documentation
permalink: /docs/JiraAgilePS/commands/Get-EpicIssue/
---
# Get-EpicIssue

## SYNOPSIS

Gets issues for an epic, including board-scoped epic issue retrieval.

## SYNTAX

### _Epic (Default)

```powershell
Get-EpicIssue [-Epic] <Epic[]> [[-PageSize] <UInt32>] [-Credential <PSCredential>] [<CommonParameters>]
```

### _BoardEpic

```powershell
Get-EpicIssue -Epic <Epic[]> -Board <Board> [[-PageSize] <UInt32>] [-Credential <PSCredential>] [<CommonParameters>]
```

### _BoardNone

```powershell
Get-EpicIssue -Board <Board> -WithoutEpic [[-PageSize] <UInt32>] [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

`Get-EpicIssue` supports these endpoints:

- `GET /rest/agile/1.0/epic/{epicId}/issue`
- `GET /rest/agile/1.0/board/{boardId}/epic/{epicId}/issue`
- `GET /rest/agile/1.0/board/{boardId}/epic/none/issue`

The command supports paging and converts issue results into JiraAgilePS issue objects.

## EXAMPLES

### EXAMPLE 1

```powershell
$epic = [AtlassianPS.JiraAgilePS.Epic]::new(10001)
JiraAgilePS\Get-EpicIssue -Epic $epic -Credential $cred
```

Returns issues for epic 10001.

### EXAMPLE 2

```powershell
$board = JiraAgilePS\Get-Board -BoardId 7 -Credential $cred
$epic = [AtlassianPS.JiraAgilePS.Epic]::new(10001)
JiraAgilePS\Get-EpicIssue -Board $board -Epic $epic -Credential $cred
```

Returns board-scoped issues for the epic.

### EXAMPLE 3

```powershell
$board = JiraAgilePS\Get-Board -BoardId 7 -Credential $cred
JiraAgilePS\Get-EpicIssue -Board $board -WithoutEpic -Credential $cred
```

Returns board issues that are not assigned to an epic.

## PARAMETERS

### -Epic

One or more epic objects/identifiers to query.

### -Board

Board object used for board-scoped epic issue retrieval.

### -WithoutEpic

Requests board issues with no epic assignment.

### -PageSize

Maximum number of issues requested per page.

### -Credential

Credentials used for Jira authentication.

## INPUTS

### AtlassianPS.JiraAgilePS.Epic

## OUTPUTS

### AtlassianPS.JiraAgilePS.Issue

## RELATED LINKS

[Get-Epic](Get-Epic.html)

[Get-BoardEpic](Get-BoardEpic.html)
