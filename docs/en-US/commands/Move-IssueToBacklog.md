---
external help file: JiraAgilePS-help.xml
Module Name: JiraAgilePS
online version: https://atlassianps.org/docs/JiraAgilePS/commands/Move-IssueToBacklog/
locale: en-US
layout: documentation
permalink: /docs/JiraAgilePS/commands/Move-IssueToBacklog/
---
# Move-IssueToBacklog

## SYNOPSIS

Moves Jira issues to the Jira Agile backlog.

## SYNTAX

```powershell
Move-IssueToBacklog [-Issue] <Object> [-Credential <PSCredential>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`Move-IssueToBacklog` removes future and active sprint assignments from one or more Jira issues by calling the Jira Agile backlog endpoint.

The command submits issue keys in request batches of 50.

When imported normally, run this command as `Move-JiraAgileIssueToBacklog`.

## EXAMPLES

### EXAMPLE 1

```powershell
$issue = Get-JiraIssue -Issue "PROJ-123" -Credential $cred
JiraAgilePS\Move-IssueToBacklog -Issue $issue -Credential $cred
```

Moves one Jira issue to the backlog.

### EXAMPLE 2

```powershell
$issues = Get-JiraIssue -Query 'project = PROJ AND sprint is not EMPTY' -Credential $cred
$issues | JiraAgilePS\Move-IssueToBacklog -Credential $cred
```

Pipes multiple Jira issues to the backlog command.

## PARAMETERS

### -Issue

Issue object or issue key to move to the backlog.

```yaml
Type: Object
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

### System.Object

Issue object(s) from JiraPS commands, for example `Get-JiraIssue`, or issue key strings.

## OUTPUTS

### System.Void

## NOTES

This command does not emit output on success.

Use `Move-JiraAgileIssueToBacklog` in normal module usage. `Move-IssueToBacklog` is the source function name.

## RELATED LINKS

[Add-IssueToSprint](Add-IssueToSprint.html)

[Get-Issue](Get-Issue.html)
