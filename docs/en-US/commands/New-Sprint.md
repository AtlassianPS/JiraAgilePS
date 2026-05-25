---
external help file: JiraAgilePS-help.xml
Module Name: JiraAgilePS
online version: https://atlassianps.org/docs/JiraAgilePS/commands/New-Sprint/
locale: en-US
layout: documentation
permalink: /docs/JiraAgilePS/commands/New-Sprint/
---
# New-Sprint

## SYNOPSIS

Creates a Jira Agile sprint.

## SYNTAX

```powershell
New-Sprint [-Board] <Board> -Name <String> [-StartDate <DateTime>] [-EndDate <DateTime>] [-Goal <String>] [-Credential <PSCredential>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`New-Sprint` creates a future sprint on a Jira Agile board.

The Jira Agile API requires a sprint name and origin board ID. Start date, end date, and goal are optional.

When imported normally, run this command as `New-JiraAgileSprint`.

## EXAMPLES

### EXAMPLE 1

```powershell
$board = JiraAgilePS\Get-Board -BoardId 7 -Credential $cred
JiraAgilePS\New-Sprint -Board $board -Name "Sprint 42" -Credential $cred
```

Creates a future sprint on board 7.

### EXAMPLE 2

```powershell
$board = JiraAgilePS\Get-Board -BoardId 7 -Credential $cred
JiraAgilePS\New-Sprint -Board $board -Name "Sprint 42" -StartDate (Get-Date) -EndDate (Get-Date).AddDays(14) -Goal "Ship API write cmdlets" -Credential $cred
```

Creates a sprint with dates and a goal.

## PARAMETERS

### -Board

Board object where the sprint will be created.

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

### -Name

Name of the sprint to create.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartDate

Optional sprint start date.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EndDate

Optional sprint end date.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Goal

Optional sprint goal.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### AtlassianPS.JiraAgilePS.Board

## OUTPUTS

### AtlassianPS.JiraAgilePS.Sprint

## NOTES

Use `New-JiraAgileSprint` in normal module usage. `New-Sprint` is the source function name.

## RELATED LINKS

[Get-Board](Get-Board.html)

[Get-Sprint](Get-Sprint.html)
