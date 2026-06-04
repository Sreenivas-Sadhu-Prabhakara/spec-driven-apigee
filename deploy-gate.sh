#!/usr/bin/env bash
# PreToolUse hook on Bash.
# "Block at submit time, not write time": only gates deploy commands. When a deploy is
# about to run, require that the spec lint passes first. Test execution is intentionally
# left to the pipeline/CI to avoid slowing every command; extend here if you want a
# local pre-deploy test gate too.
# Exit 2 => block; stderr is shown to Claude.

set -euo pipefail
input="$(cat)"

cmd="$(printf '%s' "$input" | python3 -c '
import json,sys
try:
    print(json.load(sys.stdin).get("tool_input",{}).get("command",""))
except Exception:
    print("")
')"

# Only act on Apigee deploy commands.
if printf '%s' "$cmd" | grep -Eq 'apigee-enterprise:deploy|apigeecli .*(apis|deploy)'; then
  echo "Deploy detected — running governance gate (spectral lint)..." >&2
  if ! npx spectral lint specs/*.yaml --ruleset .spectral.yaml >&2; then
    echo "BLOCKED: spec lint failed. Fix contract violations before deploying." >&2
    exit 2
  fi
  echo "Lint passed. Note: confirm apickli acceptance tests are green before promoting beyond TEST." >&2
fi
exit 0
