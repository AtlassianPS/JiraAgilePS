@{
    RootModule           = 'JiraAgilePS.psm1'
    ModuleVersion        = '0.1'
    GUID                 = '4de7d140-4fb6-4ac3-a187-82dcd762ebe9'
    Author               = 'AtlassianPS'
    CompanyName          = 'AtlassianPS.org'
    Copyright            = '(c) 2017 AtlassianPS. All rights reserved.'
    Description          = 'placeholder'
    PowerShellVersion    = '3.0'
    RequiredModules      = @("JiraPS")
    FormatsToProcess     = 'JiraAgilePS.format.ps1xml'
    # NestedModules     = @()
    FunctionsToExport    = '*'
    # CmdletsToExport   = '*'
    # VariablesToExport = '*'
    AliasesToExport      = '*'
    FileList             = @()
    PrivateData          = @{
        PSData = @{
            Tags                       = @( "rest", "api", "atlassianps", "jira", "atlassian", "agile" )
            LicenseUri                 = 'https://github.com/AtlassianPS/JiraAgilePS/blob/master/LICENSE'
            ProjectUri                 = 'https://AtlassianPS.org/module/JiraAgilePS'
            IconUri                    = 'https://AtlassianPS.org/assets/img/JiraAgilePS.png'
            ReleaseNotes               = 'https://github.com/AtlassianPS/JiraAgilePS/blob/master/CHANGELOG.md'
            ExternalModuleDependencies = 'JiraPS'
        }
    }
    DefaultCommandPrefix = 'JiraAgile'
}
