---
external help file: JiraAgilePS-help.xml
Module Name: JiraAgilePS
online version: https://atlassianps.org/docs/JiraAgilePS/commands/Get-Sprint/
locale: en-US
layout: documentation
permalink: /docs/JiraAgilePS/commands/Get-Sprint/
---
# Get-Sprint

## SYNOPSIS

Gets sprint data from Jira Agile.

## SYNTAX

### _All (Default)

```powershell
Get-Sprint [-Board] <Board> [[-State] <SprintState>] [[-PageSize] <UInt32>] [-Credential <PSCredential>] [<CommonParameters>]
```

### _ById

```powershell
Get-Sprint [-Sprint] <Sprint[]> [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

`Get-Sprint` retrieves sprints either:

- by board (optionally filtered by state), or
- by known sprint object/ID context.

When called with `-Board`, the command supports paging and can return all matching sprints.

## EXAMPLES

### EXAMPLE 1

```powershell
$board = JiraAgilePS\Get-Board -Credential $cred | Select-Object -First 1
JiraAgilePS\Get-Sprint -Board $board -Credential $cred
```

Lists sprints for a board.

### EXAMPLE 2

```powershell
$board = JiraAgilePS\Get-Board -Credential $cred | Select-Object -First 1
JiraAgilePS\Get-Sprint -Board $board -State Active -Credential $cred
```

Returns only active sprints for the selected board.

## PARAMETERS

### -Sprint

Sprint object(s) used when querying by sprint identity.

### -Board

Board object used to retrieve board sprints.

### -State

Optional sprint state filter (for example `Active`).

### -PageSize

Maximum results requested per page when listing board sprints.

### -Credential

Credentials used for Jira authentication.

## INPUTS

### AtlassianPS.JiraAgilePS.Board

Board object when using the `_All` parameter set.

### AtlassianPS.JiraAgilePS.Sprint[]

Sprint object(s) when using the `_ById` parameter set.

## OUTPUTS

### AtlassianPS.JiraAgilePS.Sprint

## RELATED LINKS

[Get-Board](Get-Board.html)

[Add-IssueToSprint](Add-IssueToSprint.html)
