#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment

    $script:Skip = Skip-IntegrationTest
}

InModuleScope JiraAgilePS {
    Describe "Agile parity" -Tag 'Integration', 'Full', 'Server', 'Cloud' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:env = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $env
            $script:fixtures = Get-TestFixture -Environment $env
            $script:createdFilters = [System.Collections.ArrayList]::new()
            $script:createdBoard = $null
            $script:testBoard = $null
            $script:createdSprint = $null
            $script:createdIssue = $null
            $script:sprints = @()

            if (-not $env.ReadOnly) {
                if (-not [string]::IsNullOrEmpty($fixtures.TestProject)) {
                    try {
                        $script:createdIssue = New-TemporaryTestIssue -Summary (New-TestResourceName -Type 'Issue') -Fixtures $fixtures -ErrorAction Stop
                    }
                    catch {
                        Write-Warning "Agile parity: could not create a temporary issue for write coverage ($($_.Exception.Message))."
                    }
                }

                $filterName = New-TestResourceName -Type 'BoardFilter'
                $filterJql = if ($script:createdIssue) { "key = $($script:createdIssue.Key)" } else { 'created >= "2099/01/01"' }
                $filter = New-JiraFilter `
                    -Name $filterName `
                    -JQL $filterJql `
                    -Description 'Auto-seeded by JiraAgilePS integration tests so Cloud and Data Center run the same board parity coverage. Safe to delete.' `
                    -Favorite `
                    -ErrorAction Stop
                $null = $script:createdFilters.Add($filter)

                $boardBody = ConvertTo-Json @{
                    name     = New-TestResourceName -Type 'Board'
                    type     = 'scrum'
                    filterId = [UInt64]$filter.Id
                }
                $script:createdBoard = Invoke-JiraMethod `
                    -Uri "$($env.CloudUrl)/rest/agile/1.0/board" `
                    -Method POST `
                    -Body $boardBody `
                    -ErrorAction Stop | ConvertTo-Board

                try {
                    $script:testBoard = Get-JiraAgileBoard -BoardId $script:createdBoard.Id -ErrorAction Stop
                }
                catch {
                    Write-Warning "Agile parity: temporary board $($script:createdBoard.Id) was created but cannot be viewed through Agile board endpoints ($($_.Exception.Message)). Falling back to an existing visible board for read coverage."
                }

                $sprintBody = ConvertTo-Json @{
                    name          = "JAPS-Sprint-$([Guid]::NewGuid().ToString('N').Substring(0, 8))"
                    originBoardId = [UInt64]$script:createdBoard.Id
                }
                $script:createdSprint = Invoke-JiraMethod `
                    -Uri "$($env.CloudUrl)/rest/agile/1.0/sprint" `
                    -Method POST `
                    -Body $sprintBody `
                    -ErrorAction Stop | ConvertTo-Sprint

            }

            if (-not $script:testBoard) {
                $script:testBoard = Get-JiraAgileBoard -PageSize 1 -ErrorAction Stop | Select-Object -First 1
            }
        }

        AfterAll {
            if ($script:createdIssue) {
                Remove-JiraIssue -IssueId $script:createdIssue.Key -Force -ErrorAction SilentlyContinue
            }
            if ($script:createdSprint) {
                Invoke-JiraMethod -Uri "$($script:env.CloudUrl)/rest/agile/1.0/sprint/$($script:createdSprint.Id)" -Method DELETE -ErrorAction SilentlyContinue
            }
            if ($script:createdBoard) {
                Invoke-JiraMethod -Uri "$($script:env.CloudUrl)/rest/agile/1.0/board/$($script:createdBoard.Id)" -Method DELETE -ErrorAction SilentlyContinue
            }
            foreach ($filter in $script:createdFilters) {
                Remove-JiraFilter -InputObject $filter -ErrorAction SilentlyContinue -Confirm:$false
            }
            Remove-JiraSession -ErrorAction SilentlyContinue
        }

        It "can establish a Jira session" {
            Get-JiraConfigServer | Should -Be $script:env.CloudUrl
            $script:session | Should -Not -BeNullOrEmpty
        }

        It "can call the Agile board endpoint" {
            { $script:boards = @(Get-JiraAgileBoard -PageSize 1 -ErrorAction Stop) } | Should -Not -Throw

            if ($script:boards.Count -gt 0) {
                $script:boards[0].PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraAgilePS.Board'
                $script:boards[0].Id | Should -Not -BeNullOrEmpty
            }
        }

        It "can retrieve a board by ID" {
            if (-not $script:testBoard) {
                Set-ItResult -Skipped -Because 'A visible Agile board is required for board-by-ID coverage.'
                return
            }

            $board = Get-JiraAgileBoard -BoardId $script:testBoard.Id -ErrorAction Stop

            $board.PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraAgilePS.Board'
            $board.Id | Should -Be $script:testBoard.Id
            $board.Name | Should -Be $script:testBoard.Name
        }

        It "can retrieve board configuration" {
            if (-not $script:testBoard) {
                Set-ItResult -Skipped -Because 'A visible Agile board is required for board configuration coverage.'
                return
            }

            $configuration = Get-JiraAgileBoardConfiguration -Board $script:testBoard -ErrorAction Stop

            $configuration | Should -Not -BeNullOrEmpty
            $configuration.Id | Should -Be $script:testBoard.Id
        }

        It "can list board sprints" {
            if (-not $script:testBoard) {
                Set-ItResult -Skipped -Because 'A visible Agile board is required for sprint list coverage.'
                return
            }

            $script:sprints = @(Get-JiraAgileSprint -Board $script:testBoard -PageSize 1 -ErrorAction Stop)

            if ($script:sprints.Count -gt 0) {
                $script:sprints[0].PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraAgilePS.Sprint'
                $script:sprints[0].Id | Should -Not -BeNullOrEmpty
            }
        }

        It "can retrieve a sprint by ID when the board has sprints" {
            if ($script:sprints.Count -eq 0) {
                Set-ItResult -Skipped -Because 'The parity board has no sprints.'
                return
            }

            $sprint = Get-JiraAgileSprint -Sprint $script:sprints[0] -ErrorAction Stop

            $sprint.PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraAgilePS.Sprint'
            $sprint.Id | Should -Be $script:sprints[0].Id
        }

        It "can list board epics" {
            if (-not $script:testBoard) {
                Set-ItResult -Skipped -Because 'A visible Agile board is required for epic list coverage.'
                return
            }

            $epics = @(Get-JiraAgileEpic -Board $script:testBoard -PageSize 1 -ErrorAction Stop)

            if ($epics.Count -gt 0) {
                $epics[0].PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraAgilePS.Epic'
                $epics[0].Id | Should -Not -BeNullOrEmpty
            }
        }

        It "can list board issues" {
            if (-not $script:testBoard) {
                Set-ItResult -Skipped -Because 'A visible Agile board is required for board issue coverage.'
                return
            }

            { @(Get-JiraAgileIssue -Board $script:testBoard -PageSize 1 -ErrorAction Stop) } | Should -Not -Throw
        }

        It "can list board backlog issues" {
            if (-not $script:testBoard) {
                Set-ItResult -Skipped -Because 'A visible Agile board is required for board backlog coverage.'
                return
            }

            { @(Get-JiraAgileIssue -Board $script:testBoard -Backlog -PageSize 1 -ErrorAction Stop) } | Should -Not -Throw
        }

        It "can add an issue to a sprint when sprint and issue fixtures exist" {
            if (-not $script:createdIssue -or $script:sprints.Count -eq 0) {
                Set-ItResult -Skipped -Because 'A temporary issue and sprint are required for Add-JiraAgileIssueToSprint coverage.'
                return
            }

            { Add-JiraAgileIssueToSprint -Issue $script:createdIssue -Sprint $script:sprints[0] -ErrorAction Stop } | Should -Not -Throw
        }
    }
}
