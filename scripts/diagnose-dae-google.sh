#!/usr/bin/env bash

set -Eeuo pipefail

VPN_CONNECTION="${1:-org2}"
DAE_SERVICE="${DAE_SERVICE:-dae}"
REPORT="${REPORT:-./dae-google-diagnostic.txt}"

exec > >(tee "$REPORT") 2>&1

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

for command in curl nmcli python3 sudo systemctl; do
    if ! command_exists "$command"; then
        printf 'ERROR: required command is missing: %s\n' "$command"
        exit 1
    fi
done

vpn_is_active() {
    nmcli -t -f NAME,TYPE connection show --active 2>/dev/null \
        | grep -Fqx "${VPN_CONNECTION}:vpn"
}

dae_is_active() {
    systemctl is-active --quiet "$DAE_SERVICE"
}

ORIGINAL_VPN_ACTIVE=false
ORIGINAL_DAE_ACTIVE=false
vpn_is_active && ORIGINAL_VPN_ACTIVE=true
dae_is_active && ORIGINAL_DAE_ACTIVE=true
RESTORED=false
DAE_STATE_CHANGED=false
VPN_STATE_CHANGED=false

restore_state() {
    local exit_code=$?

    if [[ "$RESTORED" == true ]]; then
        return "$exit_code"
    fi
    RESTORED=true

    printf '\n=== Restoring initial state ===\n'

    if [[ "$DAE_STATE_CHANGED" == true ]]; then
        if [[ "$ORIGINAL_DAE_ACTIVE" == true ]]; then
            sudo systemctl start "$DAE_SERVICE" >/dev/null 2>&1 || true
        else
            sudo systemctl stop "$DAE_SERVICE" >/dev/null 2>&1 || true
        fi
    fi

    if [[ "$VPN_STATE_CHANGED" == true ]]; then
        if [[ "$ORIGINAL_VPN_ACTIVE" == true ]]; then
            nmcli connection up "$VPN_CONNECTION" >/dev/null 2>&1 || true
        elif vpn_is_active; then
            nmcli connection down "$VPN_CONNECTION" >/dev/null 2>&1 || true
        fi
    fi

    printf 'dae_active=%s\n' "$(dae_is_active && echo yes || echo no)"
    printf '%s_active=%s\n' "$VPN_CONNECTION" "$(vpn_is_active && echo yes || echo no)"
    printf 'report=%s\n' "$REPORT"

    return "$exit_code"
}

trap restore_state EXIT INT TERM

country_from_cloudflare() {
    local family=$1
    local response

    response=$(curl "-$family" -fsS --max-time 12 \
        https://www.cloudflare.com/cdn-cgi/trace 2>/dev/null || true)

    if [[ -z "$response" ]]; then
        printf 'cloudflare_ipv%s_country=unavailable\n' "$family"
        return
    fi

    RESPONSE="$response" FAMILY="$family" python3 - <<'PY'
import os

values: dict[str, str] = {}
for line in os.environ["RESPONSE"].splitlines():
    key, separator, value = line.partition("=")
    if separator:
        values[key] = value

family = os.environ["FAMILY"]
print(f"cloudflare_ipv{family}_country={values.get('loc', 'unknown')}")
print(f"cloudflare_ipv{family}_transport={values.get('http', 'unknown')}")
PY
}

country_from_second_source() {
    local response

    response=$(curl -4 -fsS --max-time 12 https://api.country.is/ 2>/dev/null || true)
    if [[ -z "$response" ]]; then
        echo 'country_is_ipv4_country=unavailable'
        return
    fi

    RESPONSE="$response" python3 - <<'PY'
import json
import os

try:
    payload = json.loads(os.environ["RESPONSE"])
    print(f"country_is_ipv4_country={payload.get('country', 'unknown')}")
except json.JSONDecodeError:
    print("country_is_ipv4_country=unavailable")
PY
}

gemini_probe() {
    local body
    local status
    body=$(mktemp)

    status=$(curl -4 -sS -L --max-time 20 \
        -o "$body" -w '%{http_code}' \
        https://gemini.google.com/app 2>/dev/null || true)

    printf 'gemini_http_status=%s\n' "${status:-unavailable}"

    BODY="$body" python3 - <<'PY'
import os
from pathlib import Path

try:
    text = Path(os.environ["BODY"]).read_text(encoding="utf-8", errors="ignore").lower()
except OSError:
    print("gemini_country_restriction_marker=unavailable")
    raise SystemExit

markers = (
    "not currently available in your country",
    "isn't currently supported in your country",
    "is not currently supported in your country",
    "unsupported country",
    "not available in your location",
    "недоступен в вашей стране",
    "недоступно в вашей стране",
)
print(
    "gemini_country_restriction_marker="
    + ("present" if any(marker in text for marker in markers) else "not_found")
)
PY

    rm -f "$body"
}

probe_connection() {
    local label=$1

    printf '\n=== %s ===\n' "$label"
    country_from_cloudflare 4
    country_from_cloudflare 6
    country_from_second_source
    gemini_probe
}

printf '=== Safe dae/Google diagnostic ===\n'
printf 'config_read=no\n'
printf 'addresses_printed=no\n'
printf 'initial_dae_active=%s\n' "$ORIGINAL_DAE_ACTIVE"
printf 'initial_%s_active=%s\n' "$VPN_CONNECTION" "$ORIGINAL_VPN_ACTIVE"

if [[ "$ORIGINAL_VPN_ACTIVE" != true ]]; then
    printf 'ERROR: %s must be active before this comparison.\n' "$VPN_CONNECTION"
    exit 1
fi

printf '\nThe script needs sudo only to start/stop %s.\n' "$DAE_SERVICE"
sudo -v

probe_connection "OPENVPN_${VPN_CONNECTION}"

printf '\n=== Switching to dae ===\n'
nmcli connection down "$VPN_CONNECTION" >/dev/null
VPN_STATE_CHANGED=true
sudo systemctl start "$DAE_SERVICE"
DAE_STATE_CHANGED=true

for _ in {1..20}; do
    if dae_is_active; then
        break
    fi
    sleep 1
done

if ! dae_is_active; then
    echo 'ERROR: dae did not become active.'
    exit 1
fi

sleep 5
probe_connection 'DAE_HYSTERIA2'

printf '\n=== Safe routing evidence ===\n'
printf 'gemini_via_proxy_group='
if journalctl -u "$DAE_SERVICE" --since '-3 minutes' --no-pager 2>/dev/null \
    | grep -E 'sniffed=(gemini\.google\.com|gemini\.gstatic\.com)' \
    | grep -q 'outbound=proxy_group'; then
    echo yes
else
    echo not_observed
fi

printf 'google_accounts_via_proxy_group='
if journalctl -u "$DAE_SERVICE" --since '-3 minutes' --no-pager 2>/dev/null \
    | grep -E 'sniffed=(accounts\.google\.com|www\.google\.com)' \
    | grep -q 'outbound=proxy_group'; then
    echo yes
else
    echo not_observed
fi

printf '\nDiagnostic completed. No dae config fields, IP addresses, DNS servers, or credentials were printed.\n'
