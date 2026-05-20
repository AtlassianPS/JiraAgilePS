---
locale: en-US
layout: documentation
online version: https://atlassianps.org/docs/JiraAgilePS/about/authentication.html
Module Name: JiraAgilePS
permalink: /docs/JiraAgilePS/about/authentication.html
---
# Authentication

## about_JiraAgilePS_Authentication

# SHORT DESCRIPTION

JiraAgilePS uses the same authentication/session model as JiraPS.

# LONG DESCRIPTION

JiraAgilePS does not implement a separate login mechanism.
It relies on JiraPS for server configuration and authentication.

For most automation flows, do this once per session:

```powershell
Import-Module JiraPS
Import-Module JiraAgilePS

Set-JiraConfigServer 'https://yourcompany.atlassian.net'
$cred = Get-Credential
New-JiraSession -Credential $cred
```

After that, JiraAgilePS commands can run without passing `-Credential` every time.

## Cloud and Data Center

Authentication behavior is inherited from JiraPS:

- Jira Cloud: API token + email via `New-JiraSession -ApiToken -EmailAddress`
- Jira Data Center: PAT via `New-JiraSession -PersonalAccessToken`
- Legacy/basic: `-Credential`

See JiraPS authentication guidance for details and security recommendations.

# SEE ALSO

- [about_JiraPS_Authentication](https://atlassianps.org/docs/JiraPS/about/authentication.html)
- [New-JiraSession](https://atlassianps.org/docs/JiraPS/commands/New-JiraSession/)
