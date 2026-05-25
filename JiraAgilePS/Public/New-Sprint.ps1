function New-Sprint {
    # .ExternalHelp ..\JiraAgilePS-help.xml
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([AtlassianPS.JiraAgilePS.Sprint])]
    param(
        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [AtlassianPS.JiraAgilePS.Board]
        $Board,

        [Parameter()]
        [DateTime]
        $StartDate,

        [Parameter()]
        [DateTime]
        $EndDate,

        [Parameter()]
        [string]
        $Goal,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop
        $resourceUrl = "$server/rest/agile/1.0/sprint"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($Board.Id -eq 0) {
            throw "[$($MyInvocation.MyCommand.Name)] Board input must contain a non-zero Id."
        }

        $body = @{
            name          = $Name
            originBoardId = $Board.Id
        }
        if ($PSBoundParameters.ContainsKey('StartDate')) { $body['startDate'] = $StartDate }
        if ($PSBoundParameters.ContainsKey('EndDate')) { $body['endDate'] = $EndDate }
        if ($PSBoundParameters.ContainsKey('Goal')) { $body['goal'] = $Goal }

        if ($PSCmdlet.ShouldProcess($Name, "Create Jira Agile sprint on board $($Board.Id)")) {
            $requestParameter = @{
                Uri        = $resourceUrl
                Method     = "POST"
                Body       = ConvertTo-Json $body
                Credential = $Credential
                Cmdlet     = $PSCmdlet
                Verbose    = $VerbosePreference
                Debug      = $DebugPreference
            }

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$requestParameter"
            Invoke-JiraMethod @requestParameter | ConvertTo-Sprint
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
