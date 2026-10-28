# Verification policy (Lab 10.1)

A release file of hello-service is accepted only if all of these hold. The gate in `.github/workflows/verify.yml` runs this check after every release and fails the workflow if any file does not pass.

| Clause | Value |
| --- | --- |
| Trusted builder (builder.id prefix or pattern; on GitHub it changes with every tag) | GitHub Actions on GitHub-hosted runners, OIDC issuer `https://token.actions.githubusercontent.com`. builder.id is matched as a prefix, never an exact string, because it includes the tag. |
| Signing workflow (pinned in the gate, e.g. --signer-workflow) | `.github/workflows/build.yml` in wrightbrained/slsa-sandbox, pinned with `--cert-identity-regex '^https://github\.com/wrightbrained/slsa-sandbox/\.github/workflows/build\.yml@refs/tags/v'` |
| Repository | wrightbrained/slsa-sandbox (`--repo`) |
| Workflow path | Started by `.github/workflows/release.yml`, which calls `build.yml`. Only `build.yml` can sign. |
| Acceptable refs | Release tags starting with `v` (`refs/tags/v...`). Anything built from a branch, including `main`, is refused. |
| Unrecognized fields | Reject (fail closed) |
| Predicate type | `https://slsa.dev/provenance/v1` only (`--predicate-type`) |

## Gate results
| Input | Expected | Actual |
| --- | --- | --- |
| Legitimate artifact (v0.5.0 `hello-service`) | Pass | Pass. Signed by `build.yml@refs/tags/v0.5.0`. The gate in the v0.5.0 release run also passed. |
| Rebuilt, no attestation (same `hello.c` compiled on my Mac) | Fail | Fail. HTTP 404: no attestation exists for that digest. |
| Different workflow, same repo (the Lab 6.1 file signed by `forge.yml`) | Fail | Fail. "Sigstore verification failed / verifying with issuer sigstore.dev". The identity did not match. |
| The gate itself, run on GitHub against v0.1.0 | Fail | Fail. The verify job stopped with exit code 1. v0.1.0's file does have an attestation (from the v0.2.0 build, signed by `release.yml`), so it was refused on identity, not because a record was missing. |

## The Lab 6.1 forgery
Two sentences on what this shows about Modules 6 and 10: The forged file has two perfectly valid signed attestations, and my policy refused it only because it pins the signing workflow to `build.yml` from a tag, not because verification noticed the file was substituted. Module 6's isolation (signing only in a separate, reusable workflow) is what makes the forgery detectable, and Module 10's policy is what turns that difference into a refusal; without the pin, the forgery passes.

## Widened-policy test
What changed in the output when I loosened a clause: I changed the identity pattern to accept any workflow in the repository (`^https://github\.com/wrightbrained/slsa-sandbox/`) and ran it on the forged file. It printed the same green "Verification succeeded!" as a legitimate file and accepted both forged attestations, signed by `forge.yml@refs/heads/main`. The only difference anywhere in the output is the regex line in the criteria list. Nothing warned me that the policy had become weaker.

## Protecting this file
Who can change it, whether changes need review, where the record lives:
- The policy lives in two places: this file and the verify command in `.github/workflows/verify.yml`. Both are on `main`, so the ruleset `protect-main-and-release` covers them: no direct pushes, no force pushes, signed commits, and every change through a pull request.
- Only the repository owner (wrightbrained) can change them. Because I work alone, changes are merged with the logged admin exception from Lab 9.1, not reviewed by a second person. In a team, any change to `verify.yml` or this file would need approval from someone other than the author.
- The record is the pull request plus the repository activity log. The widening test above was done on my own machine only and never committed.
- A change that loosens the identity pattern, removes `--predicate-type`, or adds `continue-on-error` or `|| true` to the gate is a policy change, and gets the same review as code.
