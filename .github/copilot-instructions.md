# GitHub Copilot Entry Point

GitHub Copilot should treat these files as canonical:

- Project rules: [../AGENTS.md](../AGENTS.md)
- PowerShell rules: [ai-context/powershell-rules.md](ai-context/powershell-rules.md)

## Quick Reference

1. Scope each change to one behavior; update tests/docs/changelog when impacted and available.
2. Route Jira API interactions through `Invoke-JiraMethod` and preserve Cloud/Data Center behavior.
3. Validate from repo root with `./Tools/setup.ps1` then `Invoke-Build -Task Build, Test`.
4. This repo may have no `Tests/`; validation can warn/skip tests—report exact outcomes.
5. Public function sources are unprefixed (for example `Get-Board`) and exported with `JiraAgile` prefix.

## File Locations

- Public functions: `JiraAgilePS/Public/`
- Private functions: `JiraAgilePS/Private/`
- Tests (optional legacy coverage): `Tests/` (copied to `Release/Tests/` when present)
- Docs/help sources: `docs/en-US/commands/` (add files when command help changes)
