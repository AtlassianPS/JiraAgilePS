---
locale: en-US
layout: documentation
online version: https://atlassianps.org/docs/JiraAgilePS/about/boards-and-sprints.html
Module Name: JiraAgilePS
permalink: /docs/JiraAgilePS/about/boards-and-sprints.html
---
# Boards and Sprints

## about_JiraAgilePS_BoardsAndSprints

# SHORT DESCRIPTION

JiraAgilePS focuses on board and sprint discovery plus sprint assignment.

# LONG DESCRIPTION

The core JiraAgilePS flow is:

1. Find a board.
2. Find one or more sprints on that board.
3. Add issues to a target sprint.

```powershell
$board = JiraAgilePS\Get-Board -Credential $cred | Select-Object -First 1
$sprint = JiraAgilePS\Get-Sprint -Board $board -State Active -Credential $cred | Select-Object -First 1
JiraAgilePS\Add-IssueToSprint -Issue $issue -Sprint $sprint -Credential $cred
```

## Querying by identity vs by container

- Use `Get-Sprint -Board <Board>` to list sprints in a board.
- Use `Get-Sprint -Sprint <Sprint>` when you already have sprint identity context.

## Paging

`Get-Board` and `Get-Sprint -Board` support paging controls (`-First`, `-Skip`,
`-IncludeTotalCount`) and `-PageSize`.

Use `-First` for quick script checks and `-PageSize` when tuning API payload size.

# SEE ALSO

- [Get-Board](../commands/Get-Board.html)
- [Get-Sprint](../commands/Get-Sprint.html)
- [Add-IssueToSprint](../commands/Add-IssueToSprint.html)
