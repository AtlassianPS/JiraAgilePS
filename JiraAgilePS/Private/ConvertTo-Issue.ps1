function ConvertTo-Issue {
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

            $issue = [PSCustomObject](ConvertTo-Hashtable -InputObject ($object | Select-Object -Property *))
            $issue.PSObject.TypeNames.Insert(0, "AtlassianPS.JiraAgilePS.Issue")

            $issue
        }
    }
}

