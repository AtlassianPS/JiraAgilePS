# Integration Tests

JiraAgilePS integration tests run against live Jira Agile APIs.
They are separate from `Invoke-Build -Task Test`, which excludes `Tests/Integration` by default.

## Tracks

- Cloud is the default track and uses `JIRA_CLOUD_*` plus `JIRA_TEST_*` values.
- Server uses `CI_JIRA_TYPE=Server` and `CI_JIRA_*` values against a Dockerized Jira Data Center instance.
  The current AMPS Docker image exposes Jira Core but not Jira Software Agile REST, so Server smoke verifies container/session connectivity and skips Agile endpoint assertions with an explicit reason when the endpoint returns 404.

## Local Usage

Copy `.env.example` to `.env` and fill in the Cloud values, then run:

```powershell
Invoke-Build -Task TestIntegration -Tag Smoke
```

For the Dockerized Server track, run:

```powershell
Invoke-Build -Task StartJiraDocker
Invoke-Build -Task TestIntegration -Tag Server
Invoke-Build -Task StopJiraDocker
```

`TestIntegration` fails fast when the required environment variables for the selected track are missing.
