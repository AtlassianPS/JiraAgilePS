---
external help file: JiraAgilePS-help.xml
Module Name: JiraAgilePS
online version: https://atlassianps.org/docs/JiraAgilePS/commands/Remove-Sprint/
locale: en-US
layout: documentation
permalink: /docs/JiraAgilePS/commands/Remove-Sprint/
---
# Remove-Sprint

## SYNOPSIS

Deletes Jira Agile sprints.

## SYNTAX

```powershell
Remove-Sprint [-Sprint] <Sprint[]> [-Credential <PSCredential>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`Remove-Sprint` deletes one or more Jira Agile sprints.

When Jira deletes a sprint, open issues in that sprint are moved to the backlog.

When imported normally, run this command as `Remove-JiraAgileSprint`.

## EXAMPLES

### EXAMPLE 1

```powershell
$sprint = [AtlassianPS.JiraAgilePS.Sprint]::new(42)
JiraAgilePS\Remove-Sprint -Sprint $sprint -Credential $cred -Confirm:$false
```

Deletes sprint 42 without an interactive confirmation prompt.

### EXAMPLE 2

```powershell
$sprints = JiraAgilePS\Get-Sprint -Board $board -State Future -Credential $cred
$sprints | JiraAgilePS\Remove-Sprint -Credential $cred -WhatIf
```

Shows which future sprints would be deleted without deleting them.

## PARAMETERS

### -Sprint

Sprint object(s) to delete.

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

### System.Void

## NOTES

This command does not emit output on success.

Use `Remove-JiraAgileSprint` in normal module usage. `Remove-Sprint` is the source function name.

## RELATED LINKS

[Get-Sprint](Get-Sprint.html)

[New-Sprint](New-Sprint.html)
