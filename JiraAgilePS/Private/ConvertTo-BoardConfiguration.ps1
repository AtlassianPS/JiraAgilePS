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

            $configuration = [PSCustomObject](ConvertTo-Hashtable -InputObject ($object | Select-Object -Property *))
            $configuration.PSObject.TypeNames.Insert(0, "AtlassianPS.JiraAgilePS.BoardConfiguration")

            $configuration
        }
    }
}

