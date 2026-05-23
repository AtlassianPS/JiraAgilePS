# Public Function Tests

This directory contains unit tests for exported JiraAgilePS cmdlets.

## Pattern

Public function tests should use `Tests/Functions/Public/.template.ps1` as the starting point.
They usually cover these areas:

- Signature: parameters, types, default values, and mandatory flags.
- Behavior: REST method, URI, paging, body, and credential forwarding.
- Output: conversion helper calls and returned objects.
- Validation: accepted and rejected inputs when the cmdlet owns validation logic.

Run a focused public function test with:

```powershell
Invoke-Pester -Path 'Tests/Functions/Public/Get-Board.Unit.Tests.ps1'
```
