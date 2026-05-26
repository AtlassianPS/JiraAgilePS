function ConvertTo-JiraAgileDateString {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [DateTime]
        $Date
    )

    process {
        $Date.ToString("yyyy-MM-ddTHH:mm:ss.fffzzz", [Globalization.CultureInfo]::InvariantCulture)
    }
}
