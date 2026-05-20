function Get-Epic {
    # .ExternalHelp ..\JiraAgilePS-help.xml
    [CmdletBinding(SupportsPaging, DefaultParameterSetName = '_ById')]
    [OutputType([AtlassianPS.JiraAgilePS.Epic])]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = '_ById')]
        [AtlassianPS.JiraAgilePS.EpicTransformation()]
        [AtlassianPS.JiraAgilePS.Epic[]]
        $Epic,

        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = '_ByBoard')]
        [AtlassianPS.JiraAgilePS.BoardTransformation()]
        [AtlassianPS.JiraAgilePS.Board]
        $Board,

        [Parameter(ParameterSetName = '_ByBoard')]
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
        $resourceUrl_ById = "$server/rest/agile/1.0/epic/{0}"
        $resourceUrl_ByBoard = "$server/rest/agile/1.0/board/{0}/epic"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        switch ($PSCmdlet.ParameterSetName) {
            '_ById' {
                foreach ($_epic in $Epic) {
                    if ($_epic.Id -eq 0) {
                        throw "[$($MyInvocation.MyCommand.Name)] Epic input must contain a non-zero Id."
                    }

                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$($_epic.Id)]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_epic [$($_epic.Id)]"

                    $requestParameter = @{
                        Uri        = $resourceUrl_ById -f $_epic.Id
                        Method     = "GET"
                        Credential = $Credential
                        Cmdlet     = $PSCmdlet
                        Verbose    = $VerbosePreference
                        Debug      = $DebugPreference
                    }

                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$requestParameter"
                    Invoke-JiraMethod @requestParameter | ConvertTo-Epic
                }
            }
            '_ByBoard' {
                if ($Board.Id -eq 0) {
                    throw "[$($MyInvocation.MyCommand.Name)] Board input must contain a non-zero Id."
                }

                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing Board ID [$($Board.Id)]"
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$Board [$($Board.Id)]"

                $requestParameter = @{
                    Uri          = $resourceUrl_ByBoard -f $Board.Id
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
                Invoke-JiraMethod @requestParameter | Get-AgilePageItem | ConvertTo-Epic
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
