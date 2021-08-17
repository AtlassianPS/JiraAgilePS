function Add-IssueToSprint {
    # .ExternalHelp ..\JiraAgilePS-help.xml
    [CmdletBinding( SupportsPaging )]
    [OutputType( [void] )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline )]
        <# Waiting on JiraPS v3.0 : [AtlassianPS.JiraPS.Issue[]] #>
        $Issue,

        [Parameter( Mandatory )]
        [AtlassianPS.JiraAgilePS.Sprint]
        $Sprint,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        if (-not $Sprint.Self) {
            $Sprint = Get-Sprint -Sprint $Sprint -Credential $Credential -ErrorAction Stop
        }

        $issuesToProcess = New-Object -TypeName System.Collections.ArrayList
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($_issue in $Issue) {
            $null = $issuesToProcess.Add($_issue)
        }
    }

    end {
        while ($issuesToProcess.Count -gt 0) {
            $thisPageSize = if ($issuesToProcess.Count -lt 50) { $issuesToProcess.Count } else { 50 }
            $thisIssuePage = Select-Object -InputObject $issuesToProcess -First $thisPageSize

            $requestParameter = @{
                Uri        = "$($Sprint.Self)/issue"
                Method     = "POST"
                Body       = ConvertTo-Json @{
                    issues = @($thisIssuePage.Key) # TODO: pass Issue object with JiraPS v3.0
                    # "rankBeforeIssue": "<string>",
                    # "rankAfterIssue": "<string>",
                    # "rankCustomFieldId": 2154
                }
                Credential = $Credential
                Cmdlet     = $PSCmdlet
                Verbose    = $VerbosePreference
                Debug      = $DebugPreference
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$requestParameter"
            Invoke-JiraMethod @requestParameter

            $issuesToProcess.RemoveRange(0, $thisPageSize)
        }

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
