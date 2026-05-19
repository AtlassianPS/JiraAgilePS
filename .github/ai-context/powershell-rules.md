# JiraAgilePS PowerShell Rules

This file captures practical coding/build/test rules shared across AI entry points.

## Build and Test Commands

```powershell
./Tools/setup.ps1
Invoke-Build -Task Build, Test
```

Canonical non-interactive invocation:

```powershell
pwsh -NoLogo -NonInteractive -NoProfile -Command "Set-Location '<repo-root>'; ./Tools/setup.ps1; Invoke-Build -Task Build, Test"
```

Validation expectations for this repository's current legacy state:

- `Invoke-Build -Task Test` runs from `Release/Tests/` and may warn/skip when no `Tests/*.ps1` files exist.
- Do not claim validation passed if `Build` or `Test` fails; include failing task and error.
- During iteration, use focused `Invoke-Pester` runs when test files exist (for example `Invoke-Pester -Path 'Tests/Functions/Public/Get-Board.Unit.Tests.ps1'`).
- When changing behavior without existing coverage, add tests where practical.

## Source Layout

- Public cmdlets: `JiraAgilePS/Public/*.ps1`
- Private helpers/converters: `JiraAgilePS/Private/*.ps1`
- Public source names are unprefixed (`Get-Board`, `Get-Sprint`) and module import applies `JiraAgile` command prefix.
- Build script: `JiraAgilePS.build.ps1`
- Docs/help sources: `docs/en-US/commands/*.md`
- Tests: `Tests/**/*.ps1` (optional legacy coverage; copied into `Release/Tests/` by build when present)

## API and REST Conventions

- Route Jira API calls through `Invoke-JiraMethod`.
- Avoid introducing direct web calls in cmdlet implementations.
- Keep paging and credential behavior aligned with existing cmdlets.
- Jira Agile endpoints in this module are based on `/rest/agile/1.0`; keep Cloud/Data Center compatibility behavior explicit.

## Supported API Reference Tracks

- Cloud (supported research target): Jira Software Cloud REST API: https://developer.atlassian.com/cloud/jira/software/rest/
- Data Center/Server (supported research target): Jira Software Server/Data Center REST API: https://docs.atlassian.com/jira-software/REST/latest/
- Before adopting or changing endpoint/field behavior, verify against both references unless the task is explicitly Cloud-only or Data Center-only.

## Coding Conventions

- Follow existing cmdlet and converter patterns.
- Keep changes focused and avoid wide refactors in bug-fix branches.
- Add comments only for non-obvious constraints or decisions.
- Use `#ToDo:<Category>` markers for explicit debt tracking.

## Documentation Conventions

- User-facing command documentation belongs in `docs/en-US/commands/*.md`.
- This repo currently has sparse command docs; add/extend command pages when behavior changes.
- Include changelog updates for user-visible behavior changes.
