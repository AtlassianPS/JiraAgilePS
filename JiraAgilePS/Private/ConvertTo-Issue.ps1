function ConvertTo-Issue {
    <#
    .SYNOPSIS
        Converts Jira issue payloads to typed Issue objects.

    .DESCRIPTION
        Copies all properties from each issue response object and applies the
        AtlassianPS.JiraAgilePS.Issue typename to preserve rich output typing.
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param(
        [Parameter(ValueFromPipeline)]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($object in $InputObject) {
            if ($null -eq $object) {
                continue
            }

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraAgilePS.Issue"

            $issue = [PSCustomObject](ConvertTo-Hashtable -InputObject ($object | Select-Object -Property *))
            $issue.PSObject.TypeNames.Insert(0, "AtlassianPS.JiraAgilePS.Issue")

            $issue
        }
    }
}
