#region Dependencies
# Load the ConfluencePS namespace from C#
if (!("AtlassianPS.JiraAgilePS.Board" -as [Type])) {
    Add-Type -Path (Join-Path $PSScriptRoot JiraAgilePS.Types.cs) -ReferencedAssemblies Microsoft.CSharp, Microsoft.PowerShell.Commands.Utility, System.Management.Automation, System.Text.RegularExpressions, System.Runtime.Extensions, System.Collections
}

if (!("ArgumentCompleter" -as [Type])) {
    Add-Type -Path (Join-Path $PSScriptRoot JiraAgilePS.Attributes.cs) -ReferencedAssemblies Microsoft.CSharp, Microsoft.PowerShell.Commands.Utility, System.Management.Automation
}
#endregion Dependencies

#region Configuration
[UInt32]$script:DefaultPageSize = 25
$PSDefaultParameterValues = @{
    Disabled                        = $false
    'ConvertTo-Json:Compress'       = $true
    'ConvertTo-Json:EnumsAsStrings' = $true
}
#endregion Configuration

#region LoadFunctions
$PublicFunctions = @( Get-ChildItem -Path "$PSScriptRoot/Public/*.ps1" -ErrorAction SilentlyContinue )
$PrivateFunctions = @( Get-ChildItem -Path "$PSScriptRoot/Private/*.ps1" -ErrorAction SilentlyContinue )

# Dot source the functions
foreach ($file in @($PublicFunctions + $PrivateFunctions)) {
    try {
        . $file.FullName
    }
    catch {
        $errorItem = [System.Management.Automation.ErrorRecord]::new(
            ([System.ArgumentException]"Function not found"),
            'Load.Function',
            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
            $File
        )
        $errorItem.ErrorDetails = "Failed to import function $($file.BaseName)"
        # $PSCmdlet.ThrowTerminatingError($errorItem)
        throw $_
    }
}
Export-ModuleMember -Function $PublicFunctions.BaseName -Alias *
#endregion LoadFunctions
