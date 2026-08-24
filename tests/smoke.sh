#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
qs="${RASHELL_QUICKSHELL:-$HOME/.local/opt/rashell-runtime/quickshell}"
log="$(mktemp)"
trap 'rm -f "$log"' EXIT

set +e
timeout 6s "$qs" --no-color -p "$root" >"$log" 2>&1
status=$?
set -e

if [[ $status -ne 124 ]]; then
  cat "$log"
  exit "$status"
fi

if grep -Eiq 'TypeError|ReferenceError|Failed to load configuration|Rashell panel failed| ERROR ' "$log"; then
  cat "$log"
  exit 1
fi
