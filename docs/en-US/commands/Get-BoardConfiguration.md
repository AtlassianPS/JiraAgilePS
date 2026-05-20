---
external help file: JiraAgilePS-help.xml
Module Name: JiraAgilePS
online version: https://atlassianps.org/docs/JiraAgilePS/commands/Get-BoardConfiguration/
locale: en-US
layout: documentation
permalink: /docs/JiraAgilePS/commands/Get-BoardConfiguration/
---
# Get-BoardConfiguration

## SYNOPSIS

Gets configuration details for a Jira Agile board.

## SYNTAX

```powershell
Get-BoardConfiguration [-Board] <Board> [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

`Get-BoardConfiguration` calls:

- `GET /rest/agile/1.0/board/{boardId}/configuration`

Returns the board configuration payload as a typed JiraAgilePS board configuration object.

## EXAMPLES

### EXAMPLE 1

```powershell
$board = JiraAgilePS\Get-Board -BoardId 7 -Credential $cred
JiraAgilePS\Get-BoardConfiguration -Board $board -Credential $cred
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

[Get-Board](Get-Board.html)
