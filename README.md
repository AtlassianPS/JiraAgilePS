---
layout: module
permalink: /module/JiraAgilePS/
---
# [JiraAgilePS](https://atlassianps.org/module/JiraAgilePS)

<!-- [![GitHub release](https://img.shields.io/github/release/AtlassianPS/JiraAgilePS.svg)](https://github.com/AtlassianPS/JiraAgilePS/releases/latest) [![Build status](https://img.shields.io/appveyor/ci/AtlassianPS/JiraAgilePS/master.svg)](https://ci.appveyor.com/project/AtlassianPS/jiraAgileps/branch/master) [![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/JiraAgilePS.svg)](https://www.powershellgallery.com/packages/JiraAgilePS) ![License](https://img.shields.io/badge/license-MIT-blue.svg)-->

JiraAgilePS is a PowerShell module to interact with _Agile_, Atlassian [JIRA]'s plugin,
via a REST API, while maintaining a consistent PowerShell look and feel.

> JiraAgilePS is a module that extends [JiraPS](https://atlassianps.org/module/JiraPS).

Join the conversation on [![SlackLogo][] AtlassianPS.Slack.com](https://atlassianps.org/slack)

[SlackLogo]: https://atlassianps.org/assets/img/Slack_Mark_Web_28x28.png
<!--more-->

---

## Instructions

### Installation

Install JiraAgilePS from the [PowerShell Gallery]! `Install-Module` requires
PowerShellGet (included in PS v5, or download for v3/v4 via the gallery link)

```powershell
# One time only install:
Install-Module JiraAgilePS -Scope CurrentUser

# Check for updates occasionally:
Update-Module JiraAgilePS
```

### Usage

```powershell
# To use each session:
Import-Module JiraAgilePS
Set-JiraConfigServer 'https://YourCloud.atlassian.net'
New-JiraSession -Credential $cred
```

You can find the full documentation on our [homepage](https://atlassianps.org/docs/JiraAgilePS)
and in the console.

```powershell
# Review the help at any time!
Get-Help about_JiraAgilePS
Get-Command -Module JiraAgilePS
Get-Help Get-JiraAgileBoard -Full # or any other command
```

For more information on how to use JiraAgilePS, check out the [Documentation](https://atlassianps.org/docs/JiraAgilePS/).

### Contribute

Want to contribute to AtlassianPS? Great!
We appreciate [everyone](https://atlassianps.org/#people) who invests their time
to make our modules the best they can be.

Check out our guidelines on [Contributing] to our modules and documentation.

#### DevContainer

This repository offers a ["devcontainer"](https://containers.dev/) setup.

> **What are Development Containers?**  
> A development container (or dev container for short) allows you to use
> a container as a full-featured development environment.
> It can be used to run an application, to separate tools, libraries,
> or runtimes needed for working with a codebase,
> and to aid in continuous integration and testing.

You can use the devcontainer to spin up a fine tuned development environment with
everything you need for working on this project.

The easiest way for using DevContainers is with [VS Code](https://code.visualstudio.com/),
its extension `ms-vscode-remote.remote-containers`,
and [docker](https://docs.docker.com/engine/install/).  
When opening the repository in VS Code, it will recommend the installation of the extension.
And once installed, you will be prompted to "Reopen in Container".

## Acknowledgments

* Thanks to everyone ([Our Contributors](https://atlassianps.org/#people)) that
  helped with this module

## Useful links

* [Source Code]
* [Latest Release]
* [Submit an Issue]
* [Contributing]
* How you can help us: [List of Issues](https://github.com/AtlassianPS/JiraAgilePS/issues?q=is%3Aissue+is%3Aopen+label%3Aup-for-grabs)

## Disclaimer

Hopefully this is obvious, but:

> This is an open source project (under the [MIT license]), and all contributors are volunteers.
> All commands are executed at your own risk.
> Please have good backups before you start, because you can delete a lot of stuff if you're not careful.

<!-- reference-style links -->
  [JIRA]: https://www.atlassian.com/software/jira
  [PowerShell Gallery]: https://www.powershellgallery.com/
  [Source Code]: https://github.com/AtlassianPS/JiraAgilePS
  [Latest Release]: https://github.com/AtlassianPS/JiraAgilePS/releases/latest
  [Submit an Issue]: https://github.com/AtlassianPS/JiraAgilePS/issues/new
  [replicaJunction]: https://github.com/replicaJunction
  [MIT license]: https://github.com/AtlassianPS/JiraAgilePS/blob/master/LICENSE
  [Contributing]: http://atlassianps.org/docs/Contributing

<!-- [//]: # (Sweet online markdown editor at http://dillinger.io) -->
<!-- [//]: # ("GitHub Flavored Markdown" https://help.github.com/articles/github-flavored-markdown/) -->
