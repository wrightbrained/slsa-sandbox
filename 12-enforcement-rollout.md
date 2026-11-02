# Enforcement rollout (Lab 12.1)

**Choke point (where everything that runs must pass):** the install script, `gate/install.sh`. hello-service is a command-line binary shipped on GitHub releases, so the last handoff is the moment someone installs it. The honest limit: anyone can still download the file from the release page and copy it into place by hand, so this is a choke point only for installs that use the script. In a real environment the gate belongs wherever that cannot be skipped.
**Gate:** `gate/install.sh` runs `gh attestation verify` with the Lab 10.1 policy (signer pinned to `build.yml` from a `v` tag, SLSA provenance only) before installing, and logs every verdict to `gate/install-log.csv`.
**Mode while measuring:** audit (the word in `gate/mode`): record the verdict, install anyway. Confirmed on 2026-11-02 by installing v0.3.1, which fails the policy: it was logged as FAIL and installed.

## Coverage
Share of deploys (or workloads) whose provenance verified: 33% (3 of 9) as of 2026-11-02.
Measured with `gate/coverage.sh` over every sandbox release (v0.1.0 to v0.6.0) plus two binaries rebuilt locally with no attestation. Only v0.4.0, v0.5.0 and v0.6.0 passed. Everything released before signing moved into `build.yml` (Lab 6.1) fails today's policy.

## Failure inventory
| Workload | Bucket (fix / time-boxed exception / never verifies) | Owner | Expiry |
| --- | --- | --- | --- |
| v0.1.0, v0.2.0, v0.3.0 | Never verifies. Signed by `release.yml` (or not at all), which the policy no longer accepts. Retire them: nobody should install these. | wrightbrained | n/a |
| v0.3.1 | Time-boxed exception, only if someone still depends on it; otherwise retire. Used once via break-glass on 2026-11-02. | wrightbrained | 2026-11-30 (decide: re-release as v0.6.x or retire) |
| Local rebuilds (rebuild-1, rebuild-2) | Never verifies. Builds made outside the pipeline are not installable by design. | wrightbrained | n/a |
| (no "fix" items) | v0.4.0 and later already pass. | | |

## Break-glass (against the five properties in section 12.4)
- Who can invoke it: the repository owner (wrightbrained), by writing `gate/break-glass.json`. In a team, only the on-call lead.
- Scoped to (one service, one artifact, one deploy): one file digest. Any other file, including a later build of the same version, is still verified.
- What it costs us: for its lifetime, we install a file that nothing has verified, on someone's word. Whatever that file does, we accepted it unchecked.
- Who reads the alerts: wrightbrained. Every use opens a GitHub issue on the sandbox repository and writes a BREAK-GLASS line to `gate/install-log.csv`.
- How it expires (the mechanism, not the intention): the file carries an `expires` time; `install.sh` compares it with the clock on every run and ignores the file once that time has passed. No one has to remember to remove it.
- Who reviews each use afterwards, and when: wrightbrained, within one working day, by closing the GitHub issue with a note on whether the exception was justified.
- Exercised on (date), confirmed expired on (date): exercised 2026-11-02 at about 21:30 UTC on v0.3.1 (installed, issue opened); expired 2026-11-02 at 21:40:21 UTC, confirmed the same day when the next install of v0.3.1 was refused.

## Outage behavior
Fail open or fail closed, and why: Fail closed. If the script cannot reach GitHub to verify, the verdict is GATE-DOWN, never PASS, and in enforce mode nothing is installed. For this service an install can wait an hour; an unverified binary cannot be taken back once it has run. If an install truly cannot wait, the break-glass exists for exactly that, and it is scoped, logged and self-expiring.
Alert that fires when the gate is down: the script prints "ALERT: the verification service is unreachable (GATE-DOWN)", exits nonzero, and logs a GATE-DOWN row. In this sandbox the person installing is the person who reads it. In a team this line would page the on-call lead; without that, fail closed quietly becomes "people stop using the script", which is fail open.

## Enforcing on one service
Service: hello-service via `gate/install.sh` (mode `enforce` since 2026-11-02). Bad deploy refused? Yes, v0.3.1 was refused. Good deploy allowed? Yes, v0.6.0 was installed.
