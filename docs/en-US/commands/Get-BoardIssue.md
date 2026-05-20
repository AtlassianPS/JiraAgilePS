---
external help file: JiraAgilePS-help.xml
Module Name: JiraAgilePS
online version: https://atlassianps.org/docs/JiraAgilePS/commands/Get-JiraAgileBoardIssue/
locale: en-US
layout: documentation
permalink: /docs/JiraAgilePS/commands/Get-JiraAgileBoardIssue/
---
# Get-JiraAgileBoardIssue

## SYNOPSIS

Gets issues visible on a Jira Agile board.

## SYNTAX

```powershell
Get-JiraAgileBoardIssue [-Board] <Board> [[-PageSize] <UInt32>] [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

`Get-JiraAgileBoardIssue` calls the Jira Agile board issue endpoint:

- `GET /rest/agile/1.0/board/{boardId}/issue`

The command supports paging and converts issue results into JiraAgilePS issue objects.

## EXAMPLES

### EXAMPLE 1

```powershell
$board = JiraAgilePS\Get-JiraAgileBoard -BoardId 7 -Credential $cred
JiraAgilePS\Get-JiraAgileBoardIssue -Board $board -Credential $cred
```

Returns issues for board 7.

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

[Get-JiraAgileBacklogIssue](/docs/JiraAgilePS/commands/Get-JiraAgileBacklogIssue/)

[Commands index](/docs/JiraAgilePS/commands/)
