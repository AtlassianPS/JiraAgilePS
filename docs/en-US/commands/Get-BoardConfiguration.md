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

```yaml
Type: Board
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Credential

Credentials used for Jira authentication.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: [System.Management.Automation.PSCredential]::Empty
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### AtlassianPS.JiraAgilePS.Board

## OUTPUTS

### AtlassianPS.JiraAgilePS.BoardConfiguration

## NOTES

Use `Get-JiraAgileBoardConfiguration` in normal module usage. `Get-BoardConfiguration` is the source function name.

## RELATED LINKS

[Get-Issue](Get-Issue.html)

[Commands index](/docs/JiraAgilePS/commands/)
