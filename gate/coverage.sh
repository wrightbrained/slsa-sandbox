#!/usr/bin/env bash
# Lab 12.1 step 3: run the gate in audit mode over every release, plus any extra files you
# name, without installing anything, and print one coverage number.
# Usage: gate/coverage.sh [EXTRA_FILE ...]
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
run=$(mktemp)
echo "time,what,digest,mode,verdict,action" > "$run"
for tag in $(gh release list -R wrightbrained/slsa-sandbox --limit 100 --json tagName --jq 'reverse | .[].tagName'); do
  GATE_MODE=audit GATE_LOG=$run DRY_RUN=1 "$here/install.sh" "$tag"
done
for f in "$@"; do
  GATE_MODE=audit GATE_LOG=$run DRY_RUN=1 "$here/install.sh" --file "$f"
done
total=$(( $(wc -l < "$run") - 1 ))
pass=$(grep -c ',PASS,' "$run")
echo
echo "Coverage: $pass of $total verified = $(( 100 * pass / total ))% (measured $(date -u +%Y-%m-%d), audit mode, nothing installed)"
tail -n +2 "$run" >> "$here/install-log.csv"
