# Progress record

A few facts the lab checker can't read from GitHub, so you record them here.
Replace each placeholder in square brackets. Keep the "- Key: value" shape;
the checker reads it. Dates are YYYY-MM-DD.

## Lab 3.1
- Repository examined: cli/cli (gh v2.103.3, gh_2.103.3_macOS_arm64.zip)
- builder.id: https://github.com/cli/cli/.github/workflows/deployment.yml@refs/heads/trunk
- Digest matches subject: yes. shasum -a 256 and the subject entry for the file both give d700207e...c062

## Lab 5.1
- Runner Environment: github-hosted
- Source Repository URI: https://github.com/wrightbrained/slsa-sandbox
- Source Repository Ref: refs/tags/v0.3.1
- Build Signer URI: https://github.com/wrightbrained/slsa-sandbox/.github/workflows/release.yml@refs/tags/v0.3.1
- Not Before: 2026-10-27 19:15:32 UTC
- Not After: 2026-10-27 19:25:32 UTC

## Lab 7.1
- Bypass list: [every entity on the ruleset bypass list, including you, or "none"]

## Lab 12.1
- Choke point: [the last handoff before production]
- Coverage: [percentage of deployments that would pass]
- Coverage measured on: [date]
- Break-glass exercised on: [date]
- Break-glass expired on: [date]
- Outage posture: [fail open or fail closed]
- Outage alert: [how you find out the verifier is down]
- Enforcing service: [the one service now enforcing]
