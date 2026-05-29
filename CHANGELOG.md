# Change Log

## v0.1.0 - 2026-05-20

### Added

- Added Cloud and Data Center integration smoke test wiring with fail-fast environment validation.
- Added `Get-JiraAgileIssue` with board, backlog, and sprint parameter sets for:
  - `GET /rest/agile/1.0/board/{boardId}/issue`
  - `GET /rest/agile/1.0/board/{boardId}/backlog`
  - `GET /rest/agile/1.0/board/{boardId}/sprint/{sprintId}/issue`
- Extended `Get-JiraAgileIssue` with epic parameter sets for:
  - `GET /rest/agile/1.0/epic/{epicId}/issue`
  - `GET /rest/agile/1.0/board/{boardId}/epic/{epicId}/issue`
  - `GET /rest/agile/1.0/board/{boardId}/epic/none/issue`
- Added `Get-JiraAgileBoardConfiguration` for `GET /rest/agile/1.0/board/{boardId}/configuration`
- Added `Get-JiraAgileEpic` with direct epic and board-scoped parameter sets for:
  - `GET /rest/agile/1.0/epic/{epicId}`
  - `GET /rest/agile/1.0/board/{boardId}/epic`
- Added first-release write cmdlets for Jira Agile sprint and backlog operations:
  - `Move-JiraAgileIssueToBacklog` for `POST /rest/agile/1.0/backlog/issue`
  - `New-JiraAgileSprint` for `POST /rest/agile/1.0/sprint`
  - `Set-JiraAgileSprint` for `POST /rest/agile/1.0/sprint/{sprintId}`
  - `Remove-JiraAgileSprint` for `DELETE /rest/agile/1.0/sprint/{sprintId}`
- Added conversion helpers for paged Agile issue/epic responses and board configuration payloads

### Changed

- Harmonized integration test environment setup with JiraPS by adopting `.env.example` and a shared-style `.env` loader/validator in `Tests/Helpers/IntegrationTestTools.ps1`.
- Added JiraPS-style test guidance and private helper/converter unit coverage for JiraAgilePS.
- Documented the release readiness checklist, required secrets, dry-run validation, prerelease path, and stable release path for JiraAgilePS v0.1.0.

### Fixed

- Added support for Jira Cloud `simple` board payloads returned by the Agile board API.

<!-- reference-style links -->

[@lipkau]: https://github.com/lipkau
