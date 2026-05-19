---
applyTo: "**/*.ps1"
---

# PowerShell File Rules (GitHub Copilot)

This file applies to all `.ps1` files. It references shared rules.

**Canonical source**: [.github/ai-context/powershell-rules.md](../ai-context/powershell-rules.md)

## Quick Reference

1. **Cloud AND Data Center** — keep Jira Agile behavior compatible unless the task explicitly scopes one deployment type.
2. **Supported API tracks** — validate Agile endpoint/field changes against both Cloud and Data Center/Server references.
3. **Agile REST surface** — this module uses Jira Agile `/rest/agile/1.0` endpoints; avoid Jira Core-only assumptions.
4. **REST calls** — route command-level HTTP interactions through `Invoke-JiraMethod`.
5. **Tests required** — during iteration run targeted `Invoke-Pester` when tests exist (for example `Invoke-Pester -Path 'Tests/Functions/Public/Get-Board.Unit.Tests.ps1'`).
6. **Final validation** — run `./Tools/setup.ps1` and `Invoke-Build -Task Build, Test`; if tests are absent/warn-skipped, report exact outcomes.

For full rules, read `.github/ai-context/powershell-rules.md`.
