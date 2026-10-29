# Baseline (Lab 0.1)

Answer each question under a dated heading. You come back to question 1 in
Module 4 and again in Module 10: add a new dated heading each time and keep the
old answers. The lab checker counts the dated answers.

## Question 1: What can a consumer establish about this artifact's origin?

### Module 0 (2026-10-27)
Only that it was downloaded from the v0.1.0 release page of wrightbrained/slsa-sandbox.
Anyone with write access to the repository could have uploaded that file, built anywhere.
Nothing ties it to a commit, a workflow run or a build machine. `gh attestation verify`
finds no attestation for its digest (HTTP 404).

### Module 4 (2026-10-27)
A consumer can now check, with gh attestation verify, that each file on release v0.3.1 was built by
.github/workflows/release.yml at tag v0.3.1 in wrightbrained/slsa-sandbox, on a GitHub-hosted runner, from a
recorded commit, and signed by that workflow. They still cannot tell whether that commit was reviewed, or
whether another workflow in this repository could produce an equally valid record.

### Module 10 (2026-10-28)
A consumer can now check that each file on release v0.5.0 was signed by `.github/workflows/build.yml` running from a `v` tag in
wrightbrained/slsa-sandbox, on a GitHub-hosted runner, and my own pipeline refuses to pass a release unless that is true: the gate
in verify.yml fails the run otherwise. A file built anywhere else, or signed by any other workflow in this repository (including the
Lab 6.1 forgery), is refused. They still cannot tell whether the source change was reviewed by a second person (it was not), and the
guarantee is only as strong as the identity pattern in the policy, which loosens silently if someone edits it.

## Question 2: Which parts of your build must a consumer take entirely on trust?

### Module 0 (2026-10-27)
All of it: which commit was built, that build.sh is what actually ran, the runner image and
compiler, the actions/checkout action, the token that created the release, and that nobody
replaced the file on the release page after it was uploaded.

## Question 3: Given this binary and one you built on your laptop, what could anyone use to tell them apart?

### Module 0 (2026-10-27)
Only the bytes. Their SHA-256 digests differ (this release is sha256:cca24dda...), but nothing
published says which digest is the right one. There is no signature, no checksum file and no
provenance to compare against.

## Question 4: Your tool versions

### Module 0 (2026-10-27)
gh 2.103.3, jq 1.8.2, cosign v3.1.4, slsa-verifier not installed (optional).

## VSA freshness limit (Lab 11.1)

### Module 11 (2026-10-29)
My VSA consumer refuses any VSA older than 168 hours (one week). A week is the longest an old verdict can keep being accepted after I change the policy or stop trusting a signer, and it is long enough that a release does not need re-verifying for every deploy. Revisit this if releases become more or less frequent.
