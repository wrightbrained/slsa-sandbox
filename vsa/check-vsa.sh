#!/usr/bin/env bash
# Lab 11.1: decide about a release file using only the file and a VSA, the way a stranger would.
# Usage:  vsa/check-vsa.sh FILE VSA_BUNDLE EXPECTED_RESOURCE_URI [REQUIRED_BUILD_LEVEL]
# Options (environment):
#   TRUST_MAP=path       trust map to use (default: trust-map.json next to this script)
#   MAX_AGE_HOURS=n      override the freshness limit in the trust map
#   NOW=2026-12-01T00:00:00Z   pretend the clock says this (to test the freshness limit)
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
[ $# -ge 3 ] || { sed -n '2,8p' "$0"; exit 2; }
file=$1; bundle=$2; want_uri=$3; need=${4:-3}
map=${TRUST_MAP:-$here/trust-map.json}
type=https://slsa.dev/verification_summary/v1

refuse() { echo "REFUSE: $*"; exit 1; }
ok()     { echo "  ok  $*"; }
sha256() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1"; else shasum -a 256 "$1"; fi | cut -d' ' -f1; }

echo "Checking $(basename "$file") with VSA $(basename "$bundle")"

# 1. The signature comes from a verifier in the trust map.
match=""
count=$(jq '.verifiers | length' "$map")
for i in $(seq 0 $((count - 1))); do
  entry=$(jq -c ".verifiers[$i]" "$map")
  if [ "$(jq -r .kind <<<"$entry")" = "github-workflow" ]; then
    how=(--certificate-identity-regexp "$(jq -r .identity_regex <<<"$entry")"
         --certificate-oidc-issuer https://token.actions.githubusercontent.com)
  else
    key=$(jq -r .key <<<"$entry"); case $key in /*) ;; *) key=$here/$key ;; esac
    how=(--key "$key")
  fi
  if cosign verify-blob-attestation --bundle "$bundle" --type "$type" "${how[@]}" "$file" >/dev/null 2>&1; then
    match=$entry; break
  fi
done
[ -n "$match" ] || refuse "1/7 the VSA is not signed by any verifier in the trust map"
ok "1/7 signature verified, signed by: $(jq -r .name <<<"$match")"

statement=$(jq -c '.dsseEnvelope.payload | @base64d | fromjson' "$bundle")
pred() { jq -r "$1" <<<"$statement"; }

# 2. The VSA is about this exact file.
digest=$(sha256 "$file")
jq -e --arg d "$digest" 'any(.subject[]; .digest.sha256 == $d)' <<<"$statement" >/dev/null \
  || refuse "2/7 the VSA does not name this file (sha256:${digest:0:12}...)"
ok "2/7 subject digest matches sha256:${digest:0:12}..."

# 3. It is a VSA.
[ "$(pred .predicateType)" = "$type" ] || refuse "3/7 predicateType is $(pred .predicateType)"
ok "3/7 predicateType is $type"

# 4. The verifier it names is the one this signer is trusted to speak for.
want_id=$(jq -r .verifier_id <<<"$match")
[ "$(pred .predicate.verifier.id)" = "$want_id" ] || refuse "4/7 verifier.id is $(pred .predicate.verifier.id), expected $want_id"
ok "4/7 verifier.id is $want_id"

# 5. It verified the thing we are about to use.
[ "$(pred .predicate.resourceUri)" = "$want_uri" ] || refuse "5/7 resourceUri is $(pred .predicate.resourceUri), expected $want_uri"
ok "5/7 resourceUri is $want_uri"

# 6. The result was PASSED.
[ "$(pred .predicate.verificationResult)" = "PASSED" ] || refuse "6/7 verificationResult is $(pred .predicate.verificationResult)"
ok "6/7 verificationResult is PASSED"

# 7. The level, capped at what we trust this verifier to vouch for.
claimed=$(jq -r '[.predicate.verifiedLevels[] | select(startswith("SLSA_BUILD_LEVEL_")) | ltrimstr("SLSA_BUILD_LEVEL_") | tonumber] | max // 0' <<<"$statement")
cap=$(jq -r .max_level <<<"$match")
credited=$(( claimed < cap ? claimed : cap ))
[ "$credited" -ge "$need" ] || refuse "7/7 claims Build L$claimed, this verifier is trusted up to L$cap, so it is credited L$credited; L$need is required"
ok "7/7 claims Build L$claimed, credited L$credited (trusted up to L$cap), L$need required"

# Freshness: refuse VSAs older than the limit.
limit=${MAX_AGE_HOURS:-$(jq -r .max_age_hours "$map")}
verified=$(pred .predicate.timeVerified)
age=$(jq -n --arg t "$verified" --arg now "${NOW:-}" \
  '(((if $now == "" then now else ($now | fromdateiso8601) end) - ($t | fromdateiso8601)) / 3600) | floor')
[ "$age" -le "$limit" ] || refuse "age: verified $verified, $age hours ago; the limit is $limit hours"
ok "age: verified $verified, $age hours ago (limit $limit hours)"

echo "ACCEPT: credited SLSA Build Level $credited"
