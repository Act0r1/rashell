#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
qsb="${QSB:-/usr/lib/qt6/bin/qsb}"

if [[ ! -x "$qsb" ]]; then
    printf 'qsb not found at %s; set QSB to the Qt 6 qsb executable\n' "$qsb" >&2
    exit 1
fi

"$qsb" --qt6 \
    -o "$root/modules/weather/shaders/rainglass.frag.qsb" \
    "$root/modules/weather/shaders/rainglass.frag"
