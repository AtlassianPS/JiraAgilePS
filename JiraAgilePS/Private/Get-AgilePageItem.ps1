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
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Expanding 'issues' property from paged response"
                foreach ($issue in @($issuesProperty.Value)) {
                    $issue
                }
                continue
            }

            $valuesProperty = $object.PSObject.Properties['values']
            if ($valuesProperty) {
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Expanding 'values' property from paged response"
                foreach ($value in @($valuesProperty.Value)) {
                    $value
                }
                continue
            }

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Returning input object without page expansion"
            $object
        }
    }
}
