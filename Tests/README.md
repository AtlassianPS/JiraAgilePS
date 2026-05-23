# JiraAgilePS Testing Guide

This guide explains the JiraAgilePS test layout and the expected commands for targeted and full validation.

## Test Structure

JiraAgilePS uses Pester 5.7+.
Tests mirror the module structure so contributors can find the test for a function from its source path.

- `Tests/Functions/Public/` contains unit tests for exported cmdlets.
- `Tests/Functions/Private/` contains unit tests for internal converters and helpers.
- `Tests/Helpers/` contains shared unit and integration test helpers.
- `Tests/Integration/` contains live Jira Agile API tests and templates.

## Test Templates

Use the closest template when adding coverage:

- `Tests/Functions/Public/.template.ps1` for public cmdlets that call Jira Agile REST endpoints.
- `Tests/Functions/Private/.template.ps1` for private converters and data-shaping helpers.
- `Tests/Integration/.template.ps1` for live API integration tests.

Public cmdlet tests should cover signature, API call shape, conversion calls, and paging behavior where applicable.
Private converter tests should cover object conversion, property mapping, null handling where supported, and pipeline behavior.

## Running Tests

Run focused tests while iterating:

```powershell
Invoke-Pester -Path 'Tests/Functions/Public/Get-Board.Unit.Tests.ps1'
Invoke-Pester -Path 'Tests/Functions/Private/ConvertTo-Board.Unit.Tests.ps1'
```

Run the full repository gate before finishing work:

```powershell
./Tools/setup.ps1
Invoke-Build -Task Build, Test
```

The default test task excludes integration tests.
Run integration tests only when the change affects live Jira Agile behavior and the required environment values are available.

## Writing Tests

- Load the module with `Initialize-TestEnvironment` from `Tests/Helpers/TestTools.ps1`.
- Use `InModuleScope JiraAgilePS` when testing private functions or mocking module-internal calls.
- Keep test data local to the test file and remove personal or tenant-specific data from fixtures.
- Prefer table-driven `-TestCases` for property mapping and signature checks.
- Keep tests close to the behavior under change; do not add broad refactors as part of test-only work.
