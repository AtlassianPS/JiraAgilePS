---
external help file: JiraAgilePS-help.xml
Module Name: JiraAgilePS
online version: https://atlassianps.org/docs/JiraAgilePS/commands/Get-BoardIssue/
locale: en-US
layout: documentation
permalink: /docs/JiraAgilePS/commands/Get-BoardIssue/
---
# Get-BoardIssue

## SYNOPSIS

Gets issues visible on a Jira Agile board.

## SYNTAX

```powershell
Get-BoardIssue [-Board] <Board> [[-PageSize] <UInt32>] [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

`Get-BoardIssue` calls the Jira Agile board issue endpoint:

- `GET /rest/agile/1.0/board/{boardId}/issue`

The command supports paging and converts issue results into JiraAgilePS issue objects.

## EXAMPLES

### EXAMPLE 1

```powershell
$board = JiraAgilePS\Get-Board -BoardId 7 -Credential $cred
JiraAgilePS\Get-BoardIssue -Board $board -Credential $cred
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

[Get-Board](Get-Board.html)

[Get-BacklogIssue](Get-BacklogIssue.html)
