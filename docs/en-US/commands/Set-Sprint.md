---
external help file: JiraAgilePS-help.xml
Module Name: JiraAgilePS
online version: https://atlassianps.org/docs/JiraAgilePS/commands/Set-Sprint/
locale: en-US
layout: documentation
permalink: /docs/JiraAgilePS/commands/Set-Sprint/
---
# Set-Sprint

## SYNOPSIS

Updates Jira Agile sprints.

## SYNTAX

```powershell
Set-Sprint [-Sprint] <Sprint[]> [-Name <String>] [-State <SprintState>] [-StartDate <DateTime>] [-EndDate <DateTime>] [-Goal <String>] [-Credential <PSCredential>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`Set-Sprint` updates one or more Jira Agile sprints using the Jira Agile full-update endpoint.

The command first retrieves the current sprint and then submits existing values plus the values you provide. Jira treats this endpoint as a full update, so fields missing from both the retrieved sprint and the command parameters may be set to null by Jira.

When imported normally, run this command as `Set-JiraAgileSprint`.

## EXAMPLES

### EXAMPLE 1

```powershell
$sprint = [AtlassianPS.JiraAgilePS.Sprint]::new(42)
JiraAgilePS\Set-Sprint -Sprint $sprint -Name "Sprint 42 - revised" -Goal "Complete the release candidate" -Credential $cred
```

Updates the sprint name and goal.

### EXAMPLE 2

```powershell
$sprint = [AtlassianPS.JiraAgilePS.Sprint]::new(42)
JiraAgilePS\Set-Sprint -Sprint $sprint -State Active -StartDate (Get-Date) -EndDate (Get-Date).AddDays(14) -Credential $cred
```

Starts a future sprint by setting state and dates.

## PARAMETERS

### -Sprint

Sprint object(s) to update.

```yaml
Type: Sprint[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Name

Updated sprint name.

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

### -State

Updated sprint state.

```yaml
Type: SprintState
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartDate

Updated sprint start date.

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

Updated sprint end date.

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

Updated sprint goal.

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

### AtlassianPS.JiraAgilePS.Sprint[]

## OUTPUTS

### AtlassianPS.JiraAgilePS.Sprint

## NOTES

Use `Set-JiraAgileSprint` in normal module usage. `Set-Sprint` is the source function name.

## RELATED LINKS

[Get-Sprint](Get-Sprint.html)

[New-Sprint](New-Sprint.html)
