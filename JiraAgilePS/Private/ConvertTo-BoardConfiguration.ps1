function ConvertTo-BoardConfiguration {
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

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraAgilePS.BoardConfiguration"

            $configuration = [PSCustomObject](ConvertTo-Hashtable -InputObject ($object | Select-Object -Property *))
            $configuration.PSObject.TypeNames.Insert(0, "AtlassianPS.JiraAgilePS.BoardConfiguration")

            $configuration
        }
    }
}
