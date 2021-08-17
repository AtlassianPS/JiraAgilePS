function ConvertTo-Board {
    [CmdletBinding()]
    [OutputType( [AtlassianPS.JiraAgilePS.Board] )]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($object in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$object to custom object"

            [AtlassianPS.JiraAgilePS.Board](ConvertTo-Hashtable -InputObject ( $object | Select-Object `
                        Id,
                    Name,
                    Type,
                    Self
                )
            )
        }
    }
}


