function Move-IssueToBacklog {
    # .ExternalHelp ..\JiraAgilePS-help.xml
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        $Issue,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop
        $resourceUrl = "$server/rest/agile/1.0/backlog/issue"
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
            $thisIssuePage = @($issuesToProcess | Select-Object -First $thisPageSize)
            $issueKeys = @(
                foreach ($_issue in $thisIssuePage) {
                    if ($_issue.PSObject.Properties.Name -contains 'Key') {
                        $_issue.Key
                    }
                    else {
                        [string]$_issue
                    }
                }
            )

            if ($PSCmdlet.ShouldProcess(($issueKeys -join ', '), 'Move issues to Jira Agile backlog')) {
                $requestParameter = @{
                    Uri        = $resourceUrl
                    Method     = "POST"
                    Body       = ConvertTo-Json @{ issues = @($issueKeys) }
                    Credential = $Credential
                    Cmdlet     = $PSCmdlet
                    Verbose    = $VerbosePreference
                    Debug      = $DebugPreference
                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$requestParameter"
                Invoke-JiraMethod @requestParameter
            }

            $issuesToProcess.RemoveRange(0, $thisPageSize)
        }

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
