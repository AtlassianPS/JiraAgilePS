function Get-Board {
    # .ExternalHelp ..\JiraAgilePS-help.xml
    [CmdletBinding( SupportsPaging, DefaultParameterSetName = '_All' )]
    [OutputType( [AtlassianPS.JiraAgilePS.Board] )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = '_Search' )]
        [UInt[]]
        $BoardId,

        [Parameter()]
        [ValidateRange(1, [UInt]::MaxValue)]
        [UInt]$PageSize = $script:DefaultPageSize,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $resourceUrl = "$server/rest/agile/1.0/board"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $requestParameter = @{
            Method       = "GET"
            GetParameter = @{ maxResults = $PageSize }
            Credential   = $Credential
            Cmdlet       = $PSCmdlet
            Verbose      = $VerbosePreference
            Debug        = $DebugPreference
        }

        switch ($PSCmdlet.ParameterSetName) {
            '_All' {
                $requestParameter['Uri'] = $resourceUrl
                $requestParameter['Paging'] = $true
                # Paging
                ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
                    $requestParameter[$_] = $PSCmdlet.PagingParameters.$_
                }

                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$requestParameter"
                Invoke-JiraMethod @requestParameter | ConvertTo-Board
            }
            '_Search' {
                foreach ($_boardId in $BoardId) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_boardId]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_boardId [$_boardId]"

                    $requestParameter['Uri'] += "$resourceUrl/$_boardId"
                    $requestParameter['Paging'] = $false

                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$requestParameter"
                    Invoke-JiraMethod @requestParameter | ConvertTo-Board
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
