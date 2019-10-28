function ThrowError {
    <#
    .SYNOPSIS
        Utility to throw a terminating errorrecord
    .NOTES
        Thanks to Jaykul:
        https://github.com/PoshCode/Configuration/blob/master/Source/Metadata.psm1
    #>
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $Cmdlet = $((Get-Variable -Scope 1 PSCmdlet).Value),

        [Parameter( Position = 1, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "ExistingException" )]
        [Parameter( ParameterSetName = "NewException" )]
        [ValidateNotNullOrEmpty()]
        [System.Exception]
        $Exception,

        [Parameter( Position = 2, ParameterSetName = "NewException" )]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ExceptionType = "System.Management.Automation.RuntimeException",

        [Parameter( Position = 3, Mandatory, ParameterSetName = "NewException" )]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Message,

        [Parameter()]
        [System.Object]
        $TargetObject,

        [Parameter( Position = 10, Mandatory, ParameterSetName = "ExistingException" )]
        [Parameter( Position = 10, Mandatory, ParameterSetName = "NewException" )]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ErrorId,

        [Parameter( Position = 11, Mandatory, ParameterSetName = "ExistingException" )]
        [Parameter( Position = 11, Mandatory, ParameterSetName = "NewException" )]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorCategory]
        $Category,

        [Parameter( Position = 1, Mandatory, ParameterSetName = "Rethrow" )]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    process {
        if (-not $ErrorRecord) {
            if ($PSCmdlet.ParameterSetName -eq "NewException") {
                if ($Exception) {
                    $Exception = New-Object $ExceptionType $Message, $Exception
                }
                else {
                    $Exception = New-Object $ExceptionType $Message
                }
            }
            $errorRecord = New-Object System.Management.Automation.ErrorRecord $Exception, $ErrorId, $Category, $TargetObject
        }
        $Cmdlet.ThrowTerminatingError($errorRecord)
    }
}
