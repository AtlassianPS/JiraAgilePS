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

## PARAMETERS

### -BoardId

One or more board IDs to retrieve.

### -PageSize

Maximum results requested per page when listing boards.

### -Credential

Credentials used for Jira authentication.

## INPUTS

### System.UInt64[]

Board IDs when using the `_Search` parameter set.

## OUTPUTS

### AtlassianPS.JiraAgilePS.Board

## RELATED LINKS

[Get-Sprint](Get-Sprint.html)

[Add-IssueToSprint](Add-IssueToSprint.html)
