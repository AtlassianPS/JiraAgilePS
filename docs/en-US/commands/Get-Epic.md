---
external help file: JiraAgilePS-help.xml
Module Name: JiraAgilePS
online version: https://atlassianps.org/docs/JiraAgilePS/commands/Get-Epic/
locale: en-US
layout: documentation
permalink: /docs/JiraAgilePS/commands/Get-Epic/
---
# Get-Epic

## SYNOPSIS

Gets details for one or more Jira Agile epics.

## SYNTAX

### _ById (Default)

```powershell
Get-Epic [-Epic] <Epic[]> [[-PageSize] <UInt32>] [-Credential <PSCredential>] [<CommonParameters>]
```

### _ByBoard

```powershell
Get-Epic [-Board] <Board> [[-PageSize] <UInt32>] [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

`Get-Epic` supports:

- `GET /rest/agile/1.0/epic/{epicId}`
- `GET /rest/agile/1.0/board/{boardId}/epic`

Returns JiraAgilePS epic objects for direct epic lookup or board-scoped epic listing.

## EXAMPLES

### EXAMPLE 1

```powershell
$epic = [AtlassianPS.JiraAgilePS.Epic]::new(10001)
JiraAgilePS\Get-Epic -Epic $epic -Credential $cred
```

Returns details for epic 10001.

### EXAMPLE 2

```powershell
$board = JiraAgilePS\Get-Board -BoardId 7 -Credential $cred
JiraAgilePS\Get-Epic -Board $board -Credential $cred
```

Returns epics associated with board 7.

## PARAMETERS

### -Epic

One or more epic objects/identifiers to query.

```yaml
Type: Epic[]
Parameter Sets: _ById
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Board

Board object used for board-scoped epic retrieval.

```yaml
Type: Board
Parameter Sets: _ByBoard
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -PageSize

Maximum number of epics requested per page.

```yaml
Type: UInt32
Parameter Sets: _ByBoard
Aliases:

Required: False
Position: Named
Default value: 25
Accept pipeline input: False
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

### -IncludeTotalCount

Causes an extra output of the total count at the beginning of paged output.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Skip

Controls how many items are skipped before output starts.

```yaml
Type: UInt64
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -First

Controls how many items are returned.

```yaml
Type: UInt64
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 18446744073709551615
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### AtlassianPS.JiraAgilePS.Epic

### AtlassianPS.JiraAgilePS.Board

## OUTPUTS

### AtlassianPS.JiraAgilePS.Epic

## NOTES

Use `Get-JiraAgileEpic` in normal module usage. `Get-Epic` is the source function name.

## RELATED LINKS

[Get-Issue](Get-Issue.html)
