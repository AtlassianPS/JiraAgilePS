function Get-EpicIssue {
    # .ExternalHelp ..\JiraAgilePS-help.xml
    [CmdletBinding(SupportsPaging, DefaultParameterSetName = '_Epic')]
    [OutputType([PSObject])]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = '_Epic')]
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = '_BoardEpic')]
        [AtlassianPS.JiraAgilePS.Epic[]]
        $Epic,

        [Parameter(Mandatory, ParameterSetName = '_BoardEpic')]
        [Parameter(Mandatory, ParameterSetName = '_BoardNone')]
        [AtlassianPS.JiraAgilePS.Board]
        $Board,

        [Parameter(Mandatory, ParameterSetName = '_BoardNone')]
        [switch]
        $WithoutEpic,

        [Parameter()]
        [ValidateRange(1, 4294967295)]
        [UInt32]$PageSize = $script:DefaultPageSize,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop
        $resourceUrlEpic = "$server/rest/agile/1.0/epic/{0}/issue"
        $resourceUrlBoardEpic = "$server/rest/agile/1.0/board/{0}/epic/{1}/issue"
        $resourceUrlBoardWithoutEpic = "$server/rest/agile/1.0/board/{0}/epic/none/issue"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        switch ($PSCmdlet.ParameterSetName) {
            '_Epic' {
                foreach ($_epic in $Epic) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing Epic ID [$($_epic.Id)]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_epic [$($_epic.Id)]"

                    $requestParameter = @{
                        Uri          = $resourceUrlEpic -f $_epic.Id
                        Method       = "GET"
                        GetParameter = @{
                            maxResults = $PageSize
                        }
                        Paging       = $true
                        Credential   = $Credential
                        Cmdlet       = $PSCmdlet
                        Verbose      = $VerbosePreference
                        Debug        = $DebugPreference
                    }

                    # Paging
                    ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
                        $requestParameter[$_] = $PSCmdlet.PagingParameters.$_
                    }

                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$requestParameter"
                    Invoke-JiraMethod @requestParameter | Get-AgilePageItem | ConvertTo-Issue
                }
            }
            '_BoardEpic' {
                foreach ($_epic in $Epic) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing Epic ID [$($_epic.Id)] for Board ID [$($Board.Id)]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_epic [$($_epic.Id)]"

                    $requestParameter = @{
                        Uri          = $resourceUrlBoardEpic -f $Board.Id, $_epic.Id
                        Method       = "GET"
                        GetParameter = @{
                            maxResults = $PageSize
                        }
                        Paging       = $true
                        Credential   = $Credential
                        Cmdlet       = $PSCmdlet
                        Verbose      = $VerbosePreference
                        Debug        = $DebugPreference
                    }

                    # Paging
                    ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
                        $requestParameter[$_] = $PSCmdlet.PagingParameters.$_
                    }

                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$requestParameter"
                    Invoke-JiraMethod @requestParameter | Get-AgilePageItem | ConvertTo-Issue
                }
            }
            '_BoardNone' {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing Board ID [$($Board.Id)] with no epic"
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$Board [$($Board.Id)]"

                $requestParameter = @{
                    Uri          = $resourceUrlBoardWithoutEpic -f $Board.Id
                    Method       = "GET"
                    GetParameter = @{
                        maxResults = $PageSize
                    }
                    Paging       = $true
                    Credential   = $Credential
                    Cmdlet       = $PSCmdlet
                    Verbose      = $VerbosePreference
                    Debug        = $DebugPreference
                }

                # Paging
                ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
                    $requestParameter[$_] = $PSCmdlet.PagingParameters.$_
                }

                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$requestParameter"
                Invoke-JiraMethod @requestParameter | Get-AgilePageItem | ConvertTo-Issue
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
