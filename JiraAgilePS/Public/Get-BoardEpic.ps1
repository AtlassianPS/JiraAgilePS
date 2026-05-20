function Get-BoardEpic {
    # .ExternalHelp ..\JiraAgilePS-help.xml
    [CmdletBinding(SupportsPaging)]
    [OutputType([AtlassianPS.JiraAgilePS.Epic])]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [AtlassianPS.JiraAgilePS.Board]
        $Board,

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
        $resourceUrl = "$server/rest/agile/1.0/board/{0}/epic"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$($Board.Id)]"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$Board [$($Board.Id)]"

        $requestParameter = @{
            Uri          = $resourceUrl -f $Board.Id
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

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
