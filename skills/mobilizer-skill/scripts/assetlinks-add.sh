#!/usr/bin/env bash
#
# Append a SHA-256 certificate fingerprint to an assetlinks.json entry
# WITHOUT touching existing entries (Android App Links need every signing
# identity listed: debug keystore of each machine, upload key, and the
# Play App Signing key from Play Console).
#
#   assetlinks-add.sh <assetlinks.json> <package_name> <SHA256 AA:BB:...>
#
# Creates the package entry if it does not exist. Idempotent. Needs jq.
set -euo pipefail

[ $# -eq 3 ] || { echo "usage: $0 <assetlinks.json> <package_name> <SHA256 fingerprint>" >&2; exit 2; }
FILE="$1"; PKG="$2"; FP="$(printf '%s' "$3" | tr 'a-f' 'A-F' | tr -d '[:space:]')"
command -v jq >/dev/null || { echo "jq is required (brew/apt/pacman install jq)" >&2; exit 1; }
[[ "$FP" =~ ^([0-9A-F]{2}:){31}[0-9A-F]{2}$ ]] \
  || { echo "fingerprint must look like AA:BB:... (32 hex pairs); got: $3" >&2; exit 2; }
[ -f "$FILE" ] || echo '[]' > "$FILE"

tmp="$(mktemp)"
jq --arg pkg "$PKG" --arg fp "$FP" '
  if any(.[]; .target.package_name == $pkg) then
    map(if .target.package_name == $pkg
        then .target.sha256_cert_fingerprints |= ((. // []) | if index([$fp]) then . else . + [$fp] end)
        else . end)
  else
    . + [{
      relation: ["delegate_permission/common.handle_all_urls"],
      target: { namespace: "android_app", package_name: $pkg, sha256_cert_fingerprints: [$fp] }
    }]
  end' "$FILE" > "$tmp"
mv "$tmp" "$FILE"
echo "assetlinks: $PKG now lists $(jq -r --arg pkg "$PKG" '[.[]|select(.target.package_name==$pkg)|.target.sha256_cert_fingerprints[]]|length' "$FILE") fingerprint(s)"
echo "Reminder: takes effect only after the WEB app is deployed. Verify:"
echo "  curl -sI https://<domain>/.well-known/assetlinks.json   # 200, application/json, no redirect"
