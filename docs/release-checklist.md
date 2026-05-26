# JiraAgilePS release checklist

Issue: [#17](https://github.com/AtlassianPS/JiraAgilePS/issues/17)

Use this checklist for the first production release and later JiraAgilePS releases.

## Release readiness

- Confirm the first-release cmdlet scope in [agile-api-coverage-matrix.md](agile-api-coverage-matrix.md) is complete or intentionally deferred.
- Confirm the exact commit being tagged has a green `ci.yml` workflow run.
  `release.yml` downloads the `Release` artifact from a successful `ci.yml` run for the tagged commit and fails if that artifact is unavailable.
- Confirm the green `ci.yml` run includes build, matrix tests, Cloud smoke tests, `Release Dry Run`, and `CI Result`.
- Confirm Cloud smoke tests only skip for contexts where secrets are intentionally unavailable, such as fork or Dependabot pull requests.
  Pushes to `master` and first-party pull requests must run smoke tests successfully.
- Run broader Cloud and Server integration tracks before a production release when credentials and Docker are available.
- Confirm `CHANGELOG.md` contains the user-facing release notes for the version being published.

## Required repository secrets and variables

- `PSGALLERY_API_KEY`: required by `release.yml` to publish the module to PowerShell Gallery.
- `HOMEPAGE_PAT`: required by `release.yml` to notify `AtlassianPS.github.io` after a stable release.
- `GITHUB_TOKEN`: provided by GitHub Actions and used by `release.yml` to create the GitHub release.
- `JIRA_CLOUD_URL`, `ATLASSIAN_CLOUD_USER`, `ATLASSIAN_CLOUD_PAT`, `JIRA_TEST_PROJECT`, and `JIRA_TEST_ISSUE`: required for CI Cloud smoke tests.

## Dry-run validation

The CI workflow validates release packaging on every qualifying run with the `Release Dry Run` job:

```powershell
Invoke-Build -Task Clean, Build, SetVersion, Package -VersionToPublish v9999.0.0-alpha1
```

The job verifies that:

- `Release/JiraAgilePS/JiraAgilePS.psd1` exists.
- `Release/JiraAgilePS.zip` exists.
- the manifest version is updated to `9999.0.0`.
- the manifest prerelease label is updated to `alpha1`.

## Prerelease path

Use a prerelease tag to validate the full tagged release workflow without marking the GitHub release as stable:

```powershell
git tag v0.1.0-rc1
git push origin v0.1.0-rc1
```

Tags containing `alpha`, `beta`, or `rc` are marked as GitHub prereleases by `release.yml`.
The workflow downloads the `Release` artifact from the successful CI run for the tagged commit, publishes the module with the tag version, and uploads `Release/JiraAgilePS.zip` to the GitHub release.

## Stable release path

After the prerelease path is verified, publish the stable release from the exact commit that passed CI:

```powershell
git tag v0.1.0
git push origin v0.1.0
```

After the workflow completes, verify:

- the GitHub release exists for the tag.
- `Release/JiraAgilePS.zip` is attached to the GitHub release.
- the PowerShell Gallery package is available.
- the homepage dispatch ran for the stable release.
