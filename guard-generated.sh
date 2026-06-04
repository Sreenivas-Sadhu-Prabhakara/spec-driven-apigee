#!/usr/bin/env bash
# PreToolUse hook on Edit/Write/MultiEdit.
# Blocks manual edits to generated proxy bundles. Change the spec or template instead.
# Exit 2 => block the tool call and feed stderr back to Claude.

set -euo pipefail
input="$(cat)"

# Extract the target file path from the tool input (handles Edit/Write/MultiEdit).
path="$(printf '%s' "$input" | python3 -c '
import json,sys
try:
    d=json.load(sys.stdin)
    ti=d.get("tool_input",{})
    print(ti.get("file_path") or ti.get("path") or "")
except Exception:
    print("")
')"

case "$path" in
  */apiproxies/*)
    echo "BLOCKED: $path is a generated bundle. Do not hand-edit apiproxies/." >&2
    echo "Change the OpenAPI spec (specs/) or the template (templates/) and re-render." >&2
    exit 2
    ;;
esac
exit 0
