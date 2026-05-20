function ConvertTo-Epic {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraAgilePS.Epic])]
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

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraAgilePS.Epic"

            [AtlassianPS.JiraAgilePS.Epic](ConvertTo-Hashtable -InputObject ($object | Select-Object `
                        Id,
                    Key,
                    Name,
                    Summary,
                    @{ Name = 'Color'; Expression = {
                            if ($null -eq $object.color) {
                                $null
                            }
                            elseif ($object.color -is [String]) {
                                $object.color
                            }
                            elseif ($object.color.PSObject.Properties['key']) {
                                $object.color.key
                            }
                            elseif ($object.color.PSObject.Properties['name']) {
                                $object.color.name
                            }
                            else {
                                [String]$object.color
                            }
                        } },
                    @{ Name = 'Done'; Expression = { [bool]$object.done } },
                    Self
                )
            )
        }
    }
}
