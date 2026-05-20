function Get-BoardConfiguration {
    # .ExternalHelp ..\JiraAgilePS-help.xml
    [CmdletBinding()]
    [OutputType([PSObject])]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [AtlassianPS.JiraAgilePS.Board]
        $Board,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop
        $resourceUrl = "$server/rest/agile/1.0/board/{0}/configuration"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$($Board.Id)]"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$Board [$($Board.Id)]"

        $requestParameter = @{
            Uri        = $resourceUrl -f $Board.Id
            Method     = "GET"
            Credential = $Credential
            Cmdlet     = $PSCmdlet
            Verbose    = $VerbosePreference
            Debug      = $DebugPreference
        }

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$requestParameter"
        Invoke-JiraMethod @requestParameter | ConvertTo-BoardConfiguration
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
