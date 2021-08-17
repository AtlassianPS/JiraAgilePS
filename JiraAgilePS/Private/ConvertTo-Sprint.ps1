function ConvertTo-Sprint {
    [CmdletBinding()]
    [OutputType( [AtlassianPS.JiraAgilePS.Sprint] )]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($object in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$object to custom object"

            [AtlassianPS.JiraAgilePS.Sprint](ConvertTo-Hashtable -InputObject ( $object | Select-Object `
                        Id,
                    Name,
                    State,
                    @{ Name = 'StartDate'; Expression = { Get-Date -Date ($object.startDate) } },
                    @{ Name = 'EndDate'; Expression = { Get-Date -Date ($object.endDate) } },
                    @{ Name = 'CompleteDate'; Expression = { Get-Date -Date ($object.completeDate) } },
                    OriginBoardId,
                    Goal,
                    Self
                )
            )
        }
    }
}


