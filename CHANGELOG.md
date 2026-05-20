# Change Log

## [NEXT VERSION] - YYYY-MM-DD

### Added

- Added `Get-JiraAgileIssue` with board, backlog, and sprint parameter sets for:
  - `GET /rest/agile/1.0/board/{boardId}/issue`
  - `GET /rest/agile/1.0/board/{boardId}/backlog`
  - `GET /rest/agile/1.0/board/{boardId}/sprint/{sprintId}/issue`
- Added `Get-JiraAgileBoardConfiguration` for `GET /rest/agile/1.0/board/{boardId}/configuration`
- Added `Get-JiraAgileBoardEpic` for `GET /rest/agile/1.0/board/{boardId}/epic`
- Added `Get-JiraAgileEpic` for `GET /rest/agile/1.0/epic/{epicId}`
- Added `Get-JiraAgileEpicIssue` for epic and board-scoped epic issue retrieval endpoints
- Added conversion helpers for paged Agile issue/epic responses and board configuration payloads

### Changed

### Fixed

<!-- reference-style links -->

[@lipkau]: https://github.com/lipkau
