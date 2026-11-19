#!/usr/bin/env bash
#
# Self-test for the skill itself (run from anywhere):  skills/web-to-mobile/scripts/selftest.sh
# Renders every template with sample parameters into a temp dir and checks:
#   - no unresolved {{KEY}}; unresolved keys make render.sh fail (negative test)
#   - bash -n (and shellcheck if installed) on all rendered shell scripts
#   - XML/plist/JSON well-formedness (xmllint, jq) and Ruby syntax of the embedded script
#   - no product-specific leftovers (grep for the names of the project this was derived from)
#   - assetlinks-add.sh appends without replacing and is idempotent
set -euo pipefail
SKILL="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
fail=0; ok() { printf 'ok   %s\n' "$1"; }; bad() { printf 'FAIL %s\n' "$1"; fail=1; }

mkdir -p "$TMP/mobile"
sed -e 's/^APP_NAME=.*/APP_NAME=Acme Notes/' -e 's/^APP_SLUG=.*/APP_SLUG=acme-notes/' \
    -e 's/^APP_ID=.*/APP_ID=com.acme.notes/' -e 's#^PROD_URL=.*#PROD_URL=https://notes.acme.test#' \
    -e 's#^CALLBACK_PATHS=.*#CALLBACK_PATHS=/en/auth/callback,/de/auth/callback#' \
    -e 's/^APPLE_SIGNIN=.*/APPLE_SIGNIN=yes/' -e 's/^LOCALES=.*/LOCALES=en,de/' \
    "$SKILL/templates/MOBILE.md" > "$TMP/mobile/MOBILE.md"

OUT="$TMP/out"
if "$SKILL/scripts/render.sh" --params "$TMP/mobile/MOBILE.md" "$SKILL/templates" "$OUT" >"$TMP/render.log" 2>&1; then
  # MOBILE.md itself is a questionnaire (contains no {{}}), rendering it is harmless
  ok "all templates render"
else cat "$TMP/render.log"; bad "render"; fi

if grep -rEn '\{\{[A-Z][A-Z0-9_]*\}\}' "$OUT" >/dev/null 2>&1; then bad "unresolved placeholders remain"; else ok "no unresolved placeholders"; fi

printf 'x {{NOPE}}\n' > "$TMP/neg.txt"
if "$SKILL/scripts/render.sh" --params "$TMP/mobile/MOBILE.md" "$TMP/neg.txt" "$TMP/neg.out" >/dev/null 2>&1; then bad "render.sh accepted an unresolved key"; else ok "unresolved key is rejected"; fi

# idempotency / conflict behaviour
"$SKILL/scripts/render.sh" --params "$TMP/mobile/MOBILE.md" "$SKILL/templates/capacitor.config.ts" "$OUT/capacitor.config.ts" | grep -q '^same' && ok "re-render is a no-op" || bad "re-render not idempotent"
echo '// edited' >> "$OUT/capacitor.config.ts"
set +e; "$SKILL/scripts/render.sh" --params "$TMP/mobile/MOBILE.md" "$SKILL/templates/capacitor.config.ts" "$OUT/capacitor.config.ts" >/dev/null; rc=$?; set -e
[ "$rc" = 3 ] && ok "conflict -> exit 3, file kept" || bad "conflict handling (rc=$rc)"

while IFS= read -r -d '' f; do
  head -1 "$f" | grep -q '^#!.*bash' || continue
  bash -n "$f" && ok "bash -n ${f#"$OUT"/}" || bad "bash -n $f"
  if command -v shellcheck >/dev/null; then shellcheck -S warning "$f" >/dev/null && ok "shellcheck ${f#"$OUT"/}" || bad "shellcheck $f"; fi
done < <(find "$OUT" "$SKILL/scripts" -type f -print0)

for x in AndroidManifest.xml ios/App.entitlements ios/AppFree.entitlements ios/PrivacyInfo.xcprivacy; do
  if command -v xmllint >/dev/null; then
    # the manifest holds <data/> lines produced from CALLBACK_PATHS; it must stay well-formed
    xmllint --noout "$OUT/$( [ "$x" = AndroidManifest.xml ] && echo android/AndroidManifest.xml || echo "$x")" 2>/dev/null && ok "xml $x" || bad "xml $x"
  fi
done
command -v jq >/dev/null && for j in web/assetlinks.json web/apple-app-site-association package.json; do jq -e . "$OUT/$j" >/dev/null && ok "json $j" || bad "json $j"; done
grep -c 'android:pathPattern' "$OUT/android/AndroidManifest.xml" | grep -qx 2 && ok "one <data> per callback path" || bad "applink data lines"

if command -v ruby >/dev/null; then
  awk "/^ruby -rxcodeproj - <<'RUBY'/{f=1;next} /^RUBY\$/{f=0} f" "$OUT/ios/bin/configure" > "$TMP/cfg.rb"
  ruby -c "$TMP/cfg.rb" >/dev/null && ok "ruby syntax (ios/bin/configure)" || bad "ruby syntax"
fi

# product leakage guard: names of the project the templates were distilled from must not appear anywhere in the skill
if grep -rIil -e 'vilqo' -e 'georgian' -e 'lokali' "$SKILL" --exclude=selftest.sh >/dev/null 2>&1; then
  grep -rIil -e 'vilqo' -e 'georgian' -e 'lokali' "$SKILL" --exclude=selftest.sh; bad "product-specific leftovers"
else ok "no product-specific leftovers"; fi

# assetlinks-add
AL="$TMP/assetlinks.json"; cp "$OUT/web/assetlinks.json" "$AL"
FP1=$(printf 'AA:%.0s' {1..31})AA; FP2=$(printf 'BB:%.0s' {1..31})BB
"$SKILL/scripts/assetlinks-add.sh" "$AL" com.acme.notes "$FP1" >/dev/null
"$SKILL/scripts/assetlinks-add.sh" "$AL" com.acme.notes "$FP2" >/dev/null
"$SKILL/scripts/assetlinks-add.sh" "$AL" com.acme.notes "$FP1" >/dev/null
n=$(jq '[.[]|select(.target.package_name=="com.acme.notes")|.target.sha256_cert_fingerprints[]]|length' "$AL")
[ "$n" = 2 ] && [ "$(jq length "$AL")" = 2 ] && ok "assetlinks-add appends, no duplicates, keeps other entries" || bad "assetlinks-add ($n)"

[ "$fail" = 0 ] && echo "SELFTEST PASSED" || { echo "SELFTEST FAILED"; exit 1; }
