function Get-Issue {
    # .ExternalHelp ..\JiraAgilePS-help.xml
    [CmdletBinding(SupportsPaging, DefaultParameterSetName = '_Board')]
    [OutputType([PSObject])]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = '_Board')]
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = '_Backlog')]
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = '_Sprint')]
        [AtlassianPS.JiraAgilePS.Board]
        $Board,

        [Parameter(Mandatory, ParameterSetName = '_Backlog')]
        [switch]
        $Backlog,

        [Parameter(Position = 1, Mandatory, ValueFromPipeline, ParameterSetName = '_Sprint')]
        [AtlassianPS.JiraAgilePS.Sprint[]]
        $Sprint,

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
        $resourceUrl_Board = "$server/rest/agile/1.0/board/{0}/issue"
        $resourceUrl_Backlog = "$server/rest/agile/1.0/board/{0}/backlog"
        $resourceUrl_Sprint = "$server/rest/agile/1.0/board/{0}/sprint/{1}/issue"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $requestParameter = @{
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

        switch ($PSCmdlet.ParameterSetName) {
            '_Board' {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing Board ID [$($Board.Id)]"
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$Board [$($Board.Id)]"

                $requestParameter["Uri"] = $resourceUrl_Board -f $Board.Id
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$requestParameter"
                Invoke-JiraMethod @requestParameter | Get-AgilePageItem | ConvertTo-Issue
            }
            '_Backlog' {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing Board ID [$($Board.Id)] backlog"
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$Board [$($Board.Id)]"

                $requestParameter["Uri"] = $resourceUrl_Backlog -f $Board.Id
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$requestParameter"
                Invoke-JiraMethod @requestParameter | Get-AgilePageItem | ConvertTo-Issue
            }
            '_Sprint' {
                foreach ($_sprint in $Sprint) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing Sprint ID [$($_sprint.Id)] for Board ID [$($Board.Id)]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_sprint [$($_sprint.Id)]"

                    $requestParameter["Uri"] = $resourceUrl_Sprint -f $Board.Id, $_sprint.Id
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$requestParameter"
                    Invoke-JiraMethod @requestParameter | Get-AgilePageItem | ConvertTo-Issue
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}

