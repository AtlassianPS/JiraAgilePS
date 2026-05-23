---
external help file: JiraAgilePS-help.xml
Module Name: JiraAgilePS
online version: https://atlassianps.org/docs/JiraAgilePS/commands/Get-Board/
locale: en-US
layout: documentation
permalink: /docs/JiraAgilePS/commands/Get-Board/
---
# Get-Board

## SYNOPSIS

Gets Jira Agile boards.

## SYNTAX

### _All (Default)

```powershell
Get-Board [[-PageSize] <UInt32>] [-Credential <PSCredential>] [<CommonParameters>]
```

### _Search

```powershell
Get-Board [-BoardId] <UInt64[]> [[-PageSize] <UInt32>] [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

`Get-Board` queries Jira Agile boards through the Jira Agile REST API.

Use `-BoardId` when you already know specific board identifiers.  
Without `-BoardId`, the command returns boards with paging support.

When imported normally, run this command as `Get-JiraAgileBoard`.

## EXAMPLES

### EXAMPLE 1

```powershell
JiraAgilePS\Get-Board -Credential $cred
```

Returns boards visible to the authenticated user.

### EXAMPLE 2

```powershell
JiraAgilePS\Get-Board -BoardId 12, 45 -Credential $cred
```

Returns only the boards with IDs 12 and 45.

### EXAMPLE 3

```powershell
JiraAgilePS\Get-Board -First 10 -IncludeTotalCount -Credential $cred
```

Returns the first 10 boards and emits the total available board count.

## PARAMETERS

### -BoardId

One or more board IDs to retrieve.

```yaml
Type: UInt64[]
Parameter Sets: _Search
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -PageSize

Maximum results requested per page when listing boards.

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

### System.UInt64[]

Board IDs when using the `_Search` parameter set.

## OUTPUTS

### AtlassianPS.JiraAgilePS.Board

## NOTES

Use `Get-JiraAgileBoard` in normal module usage. `Get-Board` is the source function name.

## RELATED LINKS

[Get-Sprint](Get-Sprint.html)

[Add-IssueToSprint](Add-IssueToSprint.html)
