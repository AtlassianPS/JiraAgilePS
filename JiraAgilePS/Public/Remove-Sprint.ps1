function Remove-Sprint {
    # .ExternalHelp ..\JiraAgilePS-help.xml
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([void])]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [AtlassianPS.JiraAgilePS.Sprint[]]
        $Sprint,

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

            if ($PSCmdlet.ShouldProcess("Sprint $($_sprint.Id)", 'Delete Jira Agile sprint')) {
                $requestParameter = @{
                    Uri        = $resourceUrl -f $_sprint.Id
                    Method     = "DELETE"
                    Credential = $Credential
                    Cmdlet     = $PSCmdlet
                    Verbose    = $VerbosePreference
                    Debug      = $DebugPreference
                }

                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$requestParameter"
                Invoke-JiraMethod @requestParameter
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
