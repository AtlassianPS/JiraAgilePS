function Get-Epic {
    # .ExternalHelp ..\JiraAgilePS-help.xml
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraAgilePS.Epic])]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [AtlassianPS.JiraAgilePS.Epic[]]
        $Epic,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop
        $resourceUrl = "$server/rest/agile/1.0/epic/{0}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($_epic in $Epic) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$($_epic.Id)]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_epic [$($_epic.Id)]"

            $requestParameter = @{
                Uri        = $resourceUrl -f $_epic.Id
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

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
