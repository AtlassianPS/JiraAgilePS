# Change Log

## [NEXT VERSION] - YYYY-MM-DD

### Added

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
- Added conversion helpers for paged Agile issue/epic responses and board configuration payloads

### Changed

- Harmonized integration test environment setup with JiraPS by adopting `.env.example` and a shared-style `.env` loader/validator in `Tests/Helpers/IntegrationTestTools.ps1`.

### Fixed

<!-- reference-style links -->

[@lipkau]: https://github.com/lipkau
