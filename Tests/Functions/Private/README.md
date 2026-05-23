# Private Function Tests

This directory contains unit tests for internal JiraAgilePS helpers and converters.

## Pattern

Use `Tests/Functions/Private/.template.ps1` for converter-style functions.
Private tests should focus on the contract the public cmdlets depend on rather than duplicating implementation details.

Converter tests should cover:

- Object conversion and resulting type.
- Property mapping from Jira Agile payload fields.
- Type normalization, such as dates, URIs, booleans, and enum-backed values.
- Pipeline behavior for single and multiple inputs.
- Null input handling when the function explicitly supports it.

Run a focused private function test with:

```powershell
Invoke-Pester -Path 'Tests/Functions/Private/ConvertTo-Board.Unit.Tests.ps1'
```
