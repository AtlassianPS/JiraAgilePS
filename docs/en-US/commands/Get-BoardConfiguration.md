---
external help file: JiraAgilePS-help.xml
Module Name: JiraAgilePS
online version: https://atlassianps.org/docs/JiraAgilePS/commands/Get-JiraAgileBoardConfiguration/
locale: en-US
layout: documentation
permalink: /docs/JiraAgilePS/commands/Get-JiraAgileBoardConfiguration/
---
# Get-JiraAgileBoardConfiguration

## SYNOPSIS

Gets configuration details for a Jira Agile board.

## SYNTAX

```powershell
Get-JiraAgileBoardConfiguration [-Board] <Board> [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

`Get-JiraAgileBoardConfiguration` calls:

- `GET /rest/agile/1.0/board/{boardId}/configuration`

Returns the board configuration payload as a typed JiraAgilePS board configuration object.

## EXAMPLES

### EXAMPLE 1

```powershell
$board = JiraAgilePS\Get-JiraAgileBoard -BoardId 7 -Credential $cred
JiraAgilePS\Get-JiraAgileBoardConfiguration -Board $board -Credential $cred
```

Returns configuration details for board 7.

## PARAMETERS

### -Board

Board object to query.

### -Credential

Credentials used for Jira authentication.

## INPUTS

### AtlassianPS.JiraAgilePS.Board

## OUTPUTS

### AtlassianPS.JiraAgilePS.BoardConfiguration

## RELATED LINKS

[Get-JiraAgileIssue](/docs/JiraAgilePS/commands/Get-JiraAgileIssue/)

[Commands index](/docs/JiraAgilePS/commands/)
