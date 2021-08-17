function Get-Sprint {
    # .ExternalHelp ..\JiraAgilePS-help.xml
    [CmdletBinding( SupportsPaging, DefaultParameterSetName = '_All' )]
    [OutputType( [AtlassianPS.JiraAgilePS.Sprint] )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = '_ById' )]
        [AtlassianPS.JiraAgilePS.Sprint[]]
        $Sprint,


        [Parameter( Position, Mandatory, ValueFromPipeline, ParameterSetName = '_All' )]
        [AtlassianPS.JiraAgilePS.Board]
        $Board,

        [Parameter( ParameterSetName = '_All' )]
        [AtlassianPS.JiraAgilePS.SprintState]
        $State,

        [Parameter( ParameterSetName = '_All' )]
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

        $resourceUrl_All = "$server/rest/agile/1.0/board/{0}/sprint"
        $resourceUrl_ById = "$server/rest/agile/1.0/sprint/{0}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $requestParameter = @{
            Method     = "GET"
            Credential = $Credential
            Cmdlet     = $PSCmdlet
            Verbose    = $VerbosePreference
            Debug      = $DebugPreference
        }

        switch ($PSCmdlet.ParameterSetName) {
            '_All' {
                $requestParameter["Uri"] = $resourceUrl_All -f $Board.Id
                $requestParameter["GetParameter"] = @{
                    maxResults = $PageSize
                    state      = $State
                }
                $requestParameter["Paging"] = $true

                # Paging
                ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
                    $requestParameter[$_] = $PSCmdlet.PagingParameters.$_
                }

                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$requestParameter"
                Invoke-JiraMethod @requestParameter | ConvertTo-Sprint
            }
            '_ById' {
                foreach ($_sprint in $Sprint) {
                    $requestParameter["Uri"] = $resourceUrl_ById -f $Sprint.Id
                    $requestParameter["GetParameter"] = @{ }
                    $requestParameter["Paging"] = $false

                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$requestParameter"
                    Invoke-JiraMethod @requestParameter | ConvertTo-Sprint
                }
            }
        }

    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
