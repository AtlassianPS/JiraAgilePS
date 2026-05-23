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

When imported normally, run this command as `Get-JiraAgileSprint`.

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

### EXAMPLE 3

```powershell
$sprint = [AtlassianPS.JiraAgilePS.Sprint]::new(42)
JiraAgilePS\Get-Sprint -Sprint $sprint -Credential $cred
```

Gets sprint details by sprint ID context.

### EXAMPLE 4

```powershell
JiraAgilePS\Get-Sprint -Board $board -First 20 -IncludeTotalCount -Credential $cred
```

Returns the first 20 sprints for a board and emits the total available count.

## PARAMETERS

### -Sprint

Sprint object(s) used when querying by sprint identity.

```yaml
Type: Sprint[]
Parameter Sets: _ById
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Board

Board object used to retrieve board sprints.

```yaml
Type: Board
Parameter Sets: _All
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -State

Optional sprint state filter (for example `Active`).

```yaml
Type: SprintState
Parameter Sets: _All
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize

Maximum results requested per page when listing board sprints.

```yaml
Type: UInt32
Parameter Sets: _All
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

### AtlassianPS.JiraAgilePS.Board

Board object when using the `_All` parameter set.

### AtlassianPS.JiraAgilePS.Sprint[]

Sprint object(s) when using the `_ById` parameter set.

## OUTPUTS

### AtlassianPS.JiraAgilePS.Sprint

## NOTES

Use `Get-JiraAgileSprint` in normal module usage. `Get-Sprint` is the source function name.

## RELATED LINKS

[Get-Board](Get-Board.html)

[Add-IssueToSprint](Add-IssueToSprint.html)
