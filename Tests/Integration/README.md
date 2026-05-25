# Integration Tests

JiraAgilePS integration tests run against live Jira Agile APIs.
They are separate from `Invoke-Build -Task Test`, which excludes `Tests/Integration` by default.

## Tracks

- Cloud is the default track and uses `JIRA_CLOUD_*` plus `JIRA_TEST_*` values.
- Server uses `CI_JIRA_TYPE=Server` and `CI_JIRA_*` values against a Dockerized Jira Data Center instance.
  Server-specific fixture values use `CI_JIRA_TEST_*` so Cloud `.env` fixture values do not bleed into Data Center runs.
  The container uses AMPS with the Jira Software application configured in `Tools/amps-jira-software-runner.pom.xml`; a Core-only Jira image is not valid for JiraAgilePS integration coverage.
- CI runs only the Cloud `Smoke` tag: authentication plus one Agile board endpoint call.
- The scheduled/manual integration workflow runs the broader `Cloud` and `Server` tagged suite, including `Full` parity tests that seed temporary boards, filters, sprints, and issues.

## Local Usage

Copy `.env.example` to `.env` and fill in the Cloud values, then run:

```powershell
Invoke-Build -Task TestIntegration -Tag Smoke
```

To run the broader Cloud parity tests locally, run:

```powershell
Invoke-Build -Task TestIntegration -Tag Cloud
```

For the Dockerized Server track, run:

```powershell
Invoke-Build -Task StartJiraDocker
Invoke-Build -Task TestIntegration -Tag Server
Invoke-Build -Task StopJiraDocker
```

`TestIntegration` fails fast when the required environment variables for the selected track are missing.
