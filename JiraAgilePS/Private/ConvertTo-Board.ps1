function ConvertTo-Board {
    <#
    .SYNOPSIS
        Converts Jira Agile board payloads to Board objects.

    .DESCRIPTION
        Selects the board properties used by JiraAgilePS and casts each
        pipeline input object to [AtlassianPS.JiraAgilePS.Board].
    #>
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


