function Set-Sprint {
    # .ExternalHelp ..\JiraAgilePS-help.xml
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([AtlassianPS.JiraAgilePS.Sprint])]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [AtlassianPS.JiraAgilePS.Sprint[]]
        $Sprint,

        [Parameter()]
        [string]
        $Name,

        [Parameter()]
        [AtlassianPS.JiraAgilePS.SprintState]
        $State,

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
        $resourceUrl = "$server/rest/agile/1.0/sprint/{0}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($_sprint in $Sprint) {
            if ($_sprint.Id -eq 0) {
                throw "[$($MyInvocation.MyCommand.Name)] Sprint input must contain a non-zero Id."
            }

            $body = @{ }
            if ($PSBoundParameters.ContainsKey('Name')) { $body['name'] = $Name }
            if ($PSBoundParameters.ContainsKey('State')) { $body['state'] = $State.ToString() }
            if ($PSBoundParameters.ContainsKey('StartDate')) { $body['startDate'] = ConvertTo-JiraAgileDateString $StartDate }
            if ($PSBoundParameters.ContainsKey('EndDate')) { $body['endDate'] = ConvertTo-JiraAgileDateString $EndDate }
            if ($PSBoundParameters.ContainsKey('Goal')) { $body['goal'] = $Goal }

            if ($PSCmdlet.ShouldProcess("Sprint $($_sprint.Id)", 'Update Jira Agile sprint')) {
                $requestParameter = @{
                    Uri        = $resourceUrl -f $_sprint.Id
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
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
