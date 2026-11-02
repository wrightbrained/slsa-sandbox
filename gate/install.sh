#!/usr/bin/env bash
# Lab 12.1: the last handoff. Every install of hello-service goes through this script.
# It checks the file against the Lab 10.1 policy, records the verdict, then installs or refuses
# depending on the mode.
#
# Usage:  gate/install.sh v0.6.0          install a release
#         gate/install.sh --file PATH     check and install a file you already have
# Mode:   the word in gate/mode (audit, warn or enforce), or GATE_MODE=... for one run
#   audit   record the verdict, install anyway, say nothing
#   warn    record the verdict, install anyway, print a warning
#   enforce record the verdict, refuse anything that does not pass
# Break-glass: gate/break-glass.json skips verification for one file digest until it expires.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
repo=wrightbrained/slsa-sandbox
signer='^https://github\.com/wrightbrained/slsa-sandbox/\.github/workflows/build\.yml@refs/tags/v'
mode=${GATE_MODE:-$(tr -d '[:space:]' < "$here/mode" 2>/dev/null || echo audit)}
log=${GATE_LOG:-$here/install-log.csv}
dest=${INSTALL_DIR:-$HOME/slsa-course/installed}
sha256() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1"; else shasum -a 256 "$1"; fi | cut -d' ' -f1; }

case $mode in audit|warn|enforce) ;; *) echo "Unknown mode '$mode' (use audit, warn or enforce)"; exit 2 ;; esac
[ $# -ge 1 ] || { sed -n '2,13p' "$0"; exit 2; }

work=$(mktemp -d)
if [ "$1" = "--file" ]; then
  file=$2; label=$(basename "$2")
else
  label=$1
  gh release download "$label" -R "$repo" -p hello-service -D "$work" --clobber >/dev/null 2>&1 \
    || { echo "Could not download release $label"; exit 2; }
  file=$work/hello-service
fi
digest=sha256:$(sha256 "$file")
now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
[ -f "$log" ] || echo "time,what,digest,mode,verdict,action" > "$log"
record() { echo "$now,$label,$digest,$mode,$1,$2" >> "$log"; }
install_it() {
  [ -n "${DRY_RUN:-}" ] && return 0
  mkdir -p "$dest" && cp "$file" "$dest/hello-service" && chmod +x "$dest/hello-service"
}

# Break-glass: one digest, until a set time, and it always announces itself.
bg=$here/break-glass.json
if [ -f "$bg" ] && jq -e --arg d "$digest" '.digest == $d' "$bg" >/dev/null 2>&1; then
  if jq -e --arg now "$now" '($now | fromdateiso8601) < (.expires | fromdateiso8601)' "$bg" >/dev/null; then
    reason=$(jq -r .reason "$bg"); who=$(jq -r .invoked_by "$bg"); until=$(jq -r .expires "$bg")
    echo "BREAK-GLASS: skipping verification for $label until $until"
    echo "  reason: $reason   invoked by: $who"
    record BREAK-GLASS installed
    if gh issue create -R "$repo" --title "Break-glass used: $label ($now)" \
         --body "Verification was skipped for $label ($digest) at $now. Reason: $reason. Invoked by: $who. Expires: $until." >/dev/null 2>&1; then
      echo "  notice posted as a GitHub issue on $repo"
    else
      echo "  WARNING: could not post the notice; tell the alert reader yourself"
    fi
    install_it
    echo "$label: BREAK-GLASS ($mode mode) -> installed"
    exit 0
  fi
  echo "Break-glass for this file expired at $(jq -r .expires "$bg"); verifying normally."
fi

# Is the verifier reachable? If not, the verdict is GATE-DOWN, never PASS.
if ! gh api rate_limit >/dev/null 2>&1; then
  verdict=GATE-DOWN
  echo "ALERT: the verification service is unreachable (GATE-DOWN)" >&2
elif gh attestation verify "$file" --repo "$repo" --cert-identity-regex "$signer" \
       --predicate-type https://slsa.dev/provenance/v1 >/dev/null 2>&1; then
  verdict=PASS
else
  verdict=FAIL
fi

if [ "$verdict" != PASS ] && [ "$mode" = enforce ]; then
  record "$verdict" refused
  echo "REFUSED: $label did not pass verification ($verdict). Not installed." >&2
  exit 1
fi
[ "$verdict" != PASS ] && [ "$mode" = warn ] && echo "WARNING: $label did not pass verification ($verdict); installing anyway (warn mode)" >&2
action=installed; [ -n "${DRY_RUN:-}" ] && action="would install (dry run)"
record "$verdict" installed
install_it
echo "$label: $verdict ($mode mode) -> $action"
