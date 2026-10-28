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
- Bypass list: one entry, added in Lab 9.1: the Repository admin role (wrightbrained), in "pull request only" mode. It lets me merge my own pull requests with gh pr merge --admin because I have no second reviewer; it does not allow direct pushes, and every use is marked on the pull request. The repository admin can also edit or delete the rulesets, so if that account were compromised, none of the controls would hold.
- Rule mapping: block force pushes = continuous history; restrict deletions on main and release = continuous history; require signed commits = identity management; require a pull request = access controls; tag ruleset (restrict updates and deletions) = continuous history for release tags. Reference logging comes from GitHub's own push log, not from a rule.
- Attack 1 (amend and force push to main): blocked. "Cannot force-push to this branch", plus "Changes must be made through a pull request" and "Commits must have verified signatures".
- Attack 2 (delete release): blocked. "Cannot delete this branch".
- Attack 3 (direct push to main): blocked. "Changes must be made through a pull request" and "Commits must have verified signatures".
- Attack 4 (move tag v0.1.0): blocked. "Cannot update this protected ref."
- Source VSA: none. No source tool (source-tool or gittuf) is set up, so the sandbox is Source Level 0 for the spec's purposes. This gap goes in the Module 14 roadmap.

## Lab 12.1
- Choke point: [the last handoff before production]
- Coverage: [percentage of deployments that would pass]
- Coverage measured on: [date]
- Break-glass exercised on: [date]
- Break-glass expired on: [date]
- Outage posture: [fail open or fail closed]
- Outage alert: [how you find out the verifier is down]
- Enforcing service: [the one service now enforcing]
