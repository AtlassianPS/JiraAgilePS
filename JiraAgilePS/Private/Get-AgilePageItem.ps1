function Get-AgilePageItem {
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

            $issuesProperty = $object.PSObject.Properties['issues']
            if ($issuesProperty) {
                foreach ($issue in @($issuesProperty.Value)) {
                    $issue
                }
                continue
            }

            $valuesProperty = $object.PSObject.Properties['values']
            if ($valuesProperty) {
                foreach ($value in @($valuesProperty.Value)) {
                    $value
                }
                continue
            }

            $object
        }
    }
}

