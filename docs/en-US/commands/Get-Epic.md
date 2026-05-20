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

```powershell
Get-Epic [-Epic] <Epic[]> [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

`Get-Epic` calls:

- `GET /rest/agile/1.0/epic/{epicId}`

Returns epic details as JiraAgilePS epic objects.

## EXAMPLES

### EXAMPLE 1

```powershell
$epic = [AtlassianPS.JiraAgilePS.Epic]::new(10001)
JiraAgilePS\Get-Epic -Epic $epic -Credential $cred
```

Returns details for epic 10001.

## PARAMETERS

### -Epic

One or more epic objects/identifiers to query.

### -Credential

Credentials used for Jira authentication.

## INPUTS

### AtlassianPS.JiraAgilePS.Epic

## OUTPUTS

### AtlassianPS.JiraAgilePS.Epic

## RELATED LINKS

[Get-BoardEpic](Get-BoardEpic.html)

[Get-EpicIssue](Get-EpicIssue.html)
