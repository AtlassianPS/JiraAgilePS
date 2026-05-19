# Jira Agile REST API coverage matrix

Issue: [#11](https://github.com/AtlassianPS/JiraAgilePS/issues/11)  
Last updated: 2026-05-19

This document maps Jira Agile REST operations (Cloud + Data Center) to JiraAgilePS cmdlet coverage and locks the first-production-release cmdlet scope.

## Reference sources

- Jira Software Cloud REST intro: <https://developer.atlassian.com/cloud/jira/software/rest/intro/>
- Jira Software Cloud board operations: <https://developer.atlassian.com/cloud/jira/software/rest/api-group-board/>
- Jira Software Cloud sprint operations: <https://developer.atlassian.com/cloud/jira/software/rest/api-group-sprint/>
- Jira Software Data Center REST 9.17: <https://docs.atlassian.com/jira-software/REST/9.17.0/>

## Existing cmdlet coverage

| Cmdlet | Current endpoint coverage | Notes |
| --- | --- | --- |
| `Get-JiraAgileBoard` | `GET /rest/agile/1.0/board`, `GET /rest/agile/1.0/board/{boardId}` | Read boards |
| `Get-JiraAgileSprint` | `GET /rest/agile/1.0/board/{boardId}/sprint`, `GET /rest/agile/1.0/sprint/{sprintId}` | Read sprints |
| `Add-JiraAgileIssueToSprint` | `POST /rest/agile/1.0/sprint/{sprintId}/issue` | Add issues to sprint |

## Endpoint-to-cmdlet decision matrix

| API area | Endpoint(s) | Cloud | Data Center | Current coverage | First-release decision | Backlog linkage |
| --- | --- | --- | --- | --- | --- | --- |
| Boards | `GET /board`, `GET /board/{boardId}` | Yes | Yes | `Get-JiraAgileBoard` | Keep (fix defects before GA) | [#12](https://github.com/AtlassianPS/JiraAgilePS/issues/12) |
| Sprints | `GET /board/{boardId}/sprint`, `GET /sprint/{sprintId}` | Yes | Yes | `Get-JiraAgileSprint` | Keep (fix defects before GA) | [#12](https://github.com/AtlassianPS/JiraAgilePS/issues/12) |
| Sprint issue assignment | `POST /sprint/{sprintId}/issue` | Yes | Yes | `Add-JiraAgileIssueToSprint` | Keep (fix defects before GA) | [#12](https://github.com/AtlassianPS/JiraAgilePS/issues/12) |
| Board issues | `GET /board/{boardId}/issue` | Yes | Yes | None | Add `Get-JiraAgileBoardIssue` | [#13](https://github.com/AtlassianPS/JiraAgilePS/issues/13) |
| Backlog issues | `GET /board/{boardId}/backlog` | Yes (deprecated) | Yes | None | Add `Get-JiraAgileBacklogIssue` (document Cloud deprecation) | [#13](https://github.com/AtlassianPS/JiraAgilePS/issues/13) |
| Sprint issues | `GET /board/{boardId}/sprint/{sprintId}/issue` and/or `GET /sprint/{sprintId}/issue` | Yes | Yes | None | Add `Get-JiraAgileSprintIssue` | [#13](https://github.com/AtlassianPS/JiraAgilePS/issues/13) |
| Board configuration | `GET /board/{boardId}/configuration` | Yes | Yes | None | Add `Get-JiraAgileBoardConfiguration` | [#13](https://github.com/AtlassianPS/JiraAgilePS/issues/13) |
| Board epics | `GET /board/{boardId}/epic` | Yes | Yes | None | Add `Get-JiraAgileBoardEpic` | [#13](https://github.com/AtlassianPS/JiraAgilePS/issues/13) |
| Epic issues (board-scoped) | `GET /board/{boardId}/epic/{epicId}/issue`, `GET /board/{boardId}/epic/none/issue` | Yes | Yes | None | Add `Get-JiraAgileEpicIssue` | [#13](https://github.com/AtlassianPS/JiraAgilePS/issues/13) |
| Epic details/issues | `GET /epic/{epicId}`, `GET /epic/{epicId}/issue` | Yes | Yes | None | Add `Get-JiraAgileEpic` and `Get-JiraAgileEpicIssue` support for epic-scoped APIs | [#13](https://github.com/AtlassianPS/JiraAgilePS/issues/13) |
| Move issues to backlog | `POST /backlog/issue` | Yes | Yes | None | Add `Move-JiraAgileIssueToBacklog` | [#14](https://github.com/AtlassianPS/JiraAgilePS/issues/14) |
| Sprint create/update/delete | `POST /sprint`, `PUT /sprint/{sprintId}`, `DELETE /sprint/{sprintId}` | Yes | Yes | None | Add `New/Set/Remove-JiraAgileSprint` | [#14](https://github.com/AtlassianPS/JiraAgilePS/issues/14) |
| Sprint swap | `POST /sprint/{sprintId}/swap` | Yes | Yes | None | Defer (operationally risky, lower day-1 value) | [#11](https://github.com/AtlassianPS/JiraAgilePS/issues/11) |
| Board create/delete | `POST /board`, `DELETE /board/{boardId}` | Yes | Yes | None | Defer (admin permissions + high blast radius) | [#11](https://github.com/AtlassianPS/JiraAgilePS/issues/11) |
| Board properties | `GET/PUT/DELETE /board/{boardId}/properties/{propertyKey}` | Yes | Yes | None | Defer (app/admin use-case, not first-release core) | [#11](https://github.com/AtlassianPS/JiraAgilePS/issues/11) |
| Refined velocity settings | `GET/PUT /board/{boardId}/settings/refined-velocity` | Yes | Yes | None | Defer (niche board admin operation) | [#11](https://github.com/AtlassianPS/JiraAgilePS/issues/11) |
| Board versions | `GET /board/{boardId}/version` | Yes | Yes | None | Defer (release planning support, lower immediate priority) | [#11](https://github.com/AtlassianPS/JiraAgilePS/issues/11) |

## First-production-release cmdlet scope lock

The first-production-release scope is:

1. Stabilize existing cmdlets in [#12](https://github.com/AtlassianPS/JiraAgilePS/issues/12).
2. Deliver first-release read cmdlets in [#13](https://github.com/AtlassianPS/JiraAgilePS/issues/13):
   - `Get-JiraAgileBoardIssue`
   - `Get-JiraAgileBacklogIssue`
   - `Get-JiraAgileSprintIssue`
   - `Get-JiraAgileBoardConfiguration`
   - `Get-JiraAgileBoardEpic`
   - `Get-JiraAgileEpic`
   - `Get-JiraAgileEpicIssue`
3. Deliver first-release write cmdlets in [#14](https://github.com/AtlassianPS/JiraAgilePS/issues/14):
   - `Move-JiraAgileIssueToBacklog`
   - `New-JiraAgileSprint`
   - `Set-JiraAgileSprint`
   - `Remove-JiraAgileSprint`

All other listed endpoints remain explicitly deferred until the first-release scope above is complete.
