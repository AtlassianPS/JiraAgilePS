# AI Instructions for JiraAgilePS

> **Single source of truth for AI coding assistants.**
> Tool-specific entry-point files in this repository reference this file.

## Quick Reference (Critical Rules)

1. **Keep changes focused**: scope each commit/PR to one behavior; include tests, docs, and changelog updates when impacted and available.
2. **Always attempt repo validation**: run `./Tools/setup.ps1` and `Invoke-Build -Task Build, Test` from repo root before finalizing.
3. **Use shared Jira transport**: route Jira API calls through `Invoke-JiraMethod`.
4. **Preserve compatibility**: keep Jira Cloud/Data Center Agile behavior stable unless the change explicitly targets compatibility behavior.
5. **Do not overstate coverage**: this repo may have no `Tests/` folder; report skipped/failing validation clearly instead of claiming full test coverage.
6. **Keep user-facing docs aligned**: update `docs/en-US/commands/*.md` (or add missing command pages when needed) and `CHANGELOG.md` for visible behavior changes.

## AI Tool Compatibility

| Tool | Entry point | Canonical references |
|------|-------------|----------------------|
| GitHub Copilot | `.github/copilot-instructions.md` | `AGENTS.md`, `.github/ai-context/powershell-rules.md` |
| Cursor | `.cursor/rules/jiraagileps.mdc` | `AGENTS.md`, `.github/ai-context/powershell-rules.md` |
| Claude Code | `CLAUDE.md` | `AGENTS.md`, `.github/ai-context/powershell-rules.md` |
| Gemini/Antigravity | `GEMINI.md` | `AGENTS.md`, `.github/ai-context/powershell-rules.md` |

## Project Overview

`JiraAgilePS` adds Jira Agile cmdlets on top of JiraPS.
The repository is older and currently has less mature automated test coverage than JiraPS.

## Architecture

- Module source: `JiraAgilePS/Public/` and `JiraAgilePS/Private/`
- Public function files use unprefixed names (for example `Get-Board`) and are exported with manifest `DefaultCommandPrefix = 'JiraAgile'`.
- Build entrypoint: `JiraAgilePS.build.ps1`
- Docs/help sources: `docs/en-US/`
- Build helpers: `Tools/`
- Optional tests source: `Tests/` (copied to `Release/Tests/` by `PrepareTests` when present)

## Coding Standards

- Follow existing cmdlet patterns and avoid broad refactors in focused fixes.
- Prefer extending existing helpers/converters over duplicate logic.
- Keep comments minimal and high-value.
- Use `#ToDo:<Category>` for actionable technical debt markers.
- Remove dead code instead of leaving commented-out blocks.

## Build and Test

```powershell
./Tools/setup.ps1
Invoke-Build -Task Build, Test
```

Notes for this repository's current legacy state:

- `Invoke-Build -Task Test` runs from `Release/Tests/` and currently warns/skips when no test files are found.
- If validation fails in `Build`/`Test`, capture the exact failing task and error; do not report validation as passed.
- Use focused `Invoke-Pester` runs when test files are present.

## CI/CD

- `ci.yml` runs on `master` push/PR and executes build + matrix tests (Windows PS5/PS7, Ubuntu, macOS).
- `release.yml` handles tagged releases (`v*`) and consumes the `Release` artifact produced by `ci.yml` for the tagged commit.
- Keep workflow assumptions aligned with this flow when updating instructions or build logic.

## When Working on This Project

### Do

- Keep backward compatibility for existing cmdlet parameters and output shapes.
- Add regression tests when fixing bugs.
- Keep changelog entries concise and user-oriented.

### Do not

- Bypass `Invoke-JiraMethod` in command implementations.
- Introduce unrelated modernization changes in feature-specific branches.
- Add new runtime dependencies without strong justification.
