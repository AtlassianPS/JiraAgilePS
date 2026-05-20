function Write-DebugMessage {
    <#
    .SYNOPSIS
        Writes debug messages even when debug output is not enabled globally.

    .DESCRIPTION
        Temporarily sets DebugPreference to Continue for the pipeline scope so
        helper/debug tracing is emitted consistently, then restores the
        original preference in the end block.
    #>
    [CmdletBinding()]
    param(
        [Parameter( ValueFromPipeline )]
        [String]
        $Message
    )

    begin {
        $oldDebugPreference = $DebugPreference
        if (-not ($DebugPreference -eq "SilentlyContinue")) {
            $DebugPreference = 'Continue'
        }
    }

    process {
        Write-Debug $Message
    }

    end {
        $DebugPreference = $oldDebugPreference
    }
}
