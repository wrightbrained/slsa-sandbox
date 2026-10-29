# Trust map and VSA notes (Lab 11.1)

## Source VSA for my sandbox (step 1)
None. No source tool (source-tool or gittuf) is set up, so nothing issues a source VSA. Under SLSA v1.2 the sandbox is Source Level 0, whatever the rulesets say. This is the same gap recorded in Lab 7.1, and it goes in the Module 14 roadmap.

| Field | Value |
| --- | --- |
| verifier.id | none |
| resourceUri | none |
| verifiedLevels | none |
| subject.annotations.sourceRefs | none |

## The VSA I issued (step 2)
Issued automatically by every release, after the Lab 10.1 gate passes. Example: v0.6.0, 2026-10-29.

| Field | Value |
| --- | --- |
| Signing tool and identity | `actions/attest` (pinned v4.2.2) in `.github/workflows/vsa.yml`, signing as `vsa.yml@refs/tags/v0.6.0`. A different identity from the builder, `build.yml`. |
| verifier.id | `https://github.com/wrightbrained/slsa-sandbox/.github/workflows/vsa.yml` |
| policy (URI and digest) | `10-verification-policy.md` at commit e4a8e32, sha256:36d9234a1316... |
| inputAttestations | The build provenance for both release files, sha256:f98cd846cd12... (listed twice, because one provenance attestation covers both files) |
| verificationResult | PASSED |
| verifiedLevels | SLSA_BUILD_LEVEL_3 |
| subject digest | hello-service sha256:b455a79f8c22... and hello-service.tar.gz sha256:85d5ec2ac0f3... |

## Trust map
The working copy is `vsa/trust-map.json`, which the consumer reads.

| Verifier | Maximum level I credit | Why |
| --- | --- | --- |
| `vsa.yml` in wrightbrained/slsa-sandbox, run from a `v` tag | Build L3 | It signs with a GitHub-issued identity that only that workflow, run from a release tag, can obtain, and it only runs after the Lab 10.1 gate passes. The honest limit: the same account controls the builder and the verifier, so this is a second check, not an independent one. |
| Local test key (`vsa/local-signer.pub`) | Build L1 | A key file on one laptop. Nothing ties a signature to the policy actually being run, and anyone holding the file can sign anything. I keep it only to demonstrate capping; in real use it would be removed. |
| Anyone else | Not trusted (refused) | No VSA is accepted from a signer that is not in this map. |

## Freshness bound
Maximum age on timeVerified, and why: 168 hours (one week). A VSA is a statement about a moment. If I change the policy, or find a problem with a signer, a week is the longest an old VSA can keep being accepted. It is also long enough that a release does not need re-verifying for every deploy. This is the kind of number teams set once and forget, so I will revisit it when the release rhythm changes (recorded in BASELINE.md too).

## Seven-check consumer (step 3)
`vsa/check-vsa.sh FILE VSA_BUNDLE EXPECTED_RESOURCE_URI [REQUIRED_LEVEL]`
- [x] Signature against a trusted verifier identity (cosign, against each entry in the trust map)
- [x] Subject digest matches the artifact
- [x] predicateType is https://slsa.dev/verification_summary/v1
- [x] verifier.id is one I trust (and the one that signer is allowed to speak for)
- [x] resourceUri is the artifact I expected
- [x] verificationResult is PASSED
- [x] verifiedLevels include what I require, capped at the signer's maximum
- [x] Plus freshness: timeVerified no older than 168 hours

Results on 2026-10-29: the v0.6.0 VSA was accepted at Build L3; the same VSA checked as if it were December 1 was refused as 778 hours old.

## Capped, not refused (step 6)
The VSA I signed with a different identity, the level it claimed, and the level my consumer credited: I took the exact predicate from the v0.6.0 VSA and re-signed it with a local cosign key. Before that key was in the trust map, the consumer refused it at check 1 (not signed by a trusted verifier). After I added the key with a maximum of Build L1, the same VSA, still claiming Build L3, was refused when L3 was required and accepted as Build L1 when L1 was required. The claim did not change; how much I believed it did.
