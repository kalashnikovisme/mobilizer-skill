#!/usr/bin/env bash
#
# Renders web-to-mobile templates into a target repository.
#
#   render.sh [--params mobile/MOBILE.md] [--force] SRC DEST
#
# SRC   a template file or directory (inside the skill's templates/ folder)
# DEST  the output file or directory in the target repo
#
# Parameters come from the fenced ```env block of mobile/MOBILE.md
# (KEY=VALUE lines; no secrets ever). Every {{KEY}} in a text template is
# replaced. Any {{KEY}} that cannot be resolved is an ERROR (exit 1), so a
# half-rendered file never reaches the repo.
#
# Existing files in DEST that differ from the rendered output are NOT
# overwritten unless --force is given; they are listed and the script exits 3
# so the caller must merge deliberately (idempotent re-runs stay safe).
#
# Derived keys (computed, may be overridden in the env block):
#   APP_ID_PATH          APP_ID with dots -> slashes (Android package dir)
#   PROD_HOST            host part of PROD_URL
#   APP_PASCAL           APP_NAME stripped to [A-Za-z0-9]
#   UA_ANDROID / UA_IOS  <APP_PASCAL>AndroidApp / <APP_PASCAL>IosApp
#   ANDROID_APPLINK_DATA one <data .../> line per path in CALLBACK_PATHS
#   AASA_CALLBACK_COMPONENTS one iOS components entry per CALLBACK_PATHS path
#   MOBILE_NPM / MOBILE_CAP  how Node tooling runs (default npm / npx cap; e.g. 'dip mobile-npm' / 'dip mobile-cap')
#   BRIDGE_REGISTER_PLUGINS / ENT_APPLESIGNIN   depend on APPLE_SIGNIN=yes|no (default no)
set -euo pipefail

PARAMS="mobile/MOBILE.md"
FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --params) PARAMS="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    -h|--help) sed -n '2,24p' "$0"; exit 0 ;;
    --) shift; break ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) break ;;
  esac
done
[ $# -eq 2 ] || { echo "usage: render.sh [--params FILE] [--force] SRC DEST" >&2; exit 2; }
SRC="$1"; DEST="$2"
[ -e "$SRC" ] || { echo "template not found: $SRC" >&2; exit 2; }
[ -f "$PARAMS" ] || { echo "params file not found: $PARAMS (run the questionnaire first)" >&2; exit 2; }

# --- load parameters -------------------------------------------------------
declare -A P=()
in_block=0
while IFS= read -r line || [ -n "$line" ]; do
  if [ "$in_block" = 0 ]; then
    [ "$line" = '```env' ] && in_block=1
    continue
  fi
  [ "$line" = '```' ] && break
  case "$line" in ''|'#'*) continue ;; esac
  case "$line" in *=*) ;; *) continue ;; esac
  key="${line%%=*}"; val="${line#*=}"
  key="${key//[[:space:]]/}"
  val="${val%% #*}"                       # strip trailing " # comment"
  val="${val#"${val%%[![:space:]]*}"}"    # ltrim
  val="${val%"${val##*[![:space:]]}"}"    # rtrim
  [[ "$key" =~ ^[A-Z][A-Z0-9_]*$ ]] || continue
  P[$key]="$val"
done < "$PARAMS"

for req in APP_NAME APP_SLUG APP_ID PROD_URL; do
  [ -n "${P[$req]:-}" ] || { echo "MOBILE.md is missing required key $req" >&2; exit 2; }
done
[[ "${P[APP_ID]}" =~ ^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$ ]] \
  || { echo "APP_ID '${P[APP_ID]}' is not reverse-DNS (e.g. com.example.app)" >&2; exit 2; }
[[ "${P[PROD_URL]}" =~ ^https://[^/]+/?$ ]] \
  || { echo "PROD_URL '${P[PROD_URL]}' must be https://host (no path)" >&2; exit 2; }

P[PROD_URL]="${P[PROD_URL]%/}"
: "${P[APP_ID_PATH]:=${P[APP_ID]//./\/}}"
: "${P[PROD_HOST]:=${P[PROD_URL]#https://}}"
pascal="${P[APP_NAME]//[^A-Za-z0-9]/}"
: "${P[APP_PASCAL]:=$pascal}"
: "${P[UA_ANDROID]:=${P[APP_PASCAL]}AndroidApp}"
: "${P[UA_IOS]:=${P[APP_PASCAL]}IosApp}"
: "${P[BRAND_COLOR]:=#FFFFFF}"
: "${P[CALLBACK_PATHS]:=/auth/callback}"
: "${P[SECRETS_STORE]:=none}"
: "${P[SECRETS_REF_DEV]:=}"
: "${P[SECRETS_REF_PROD]:=}"
: "${P[LOCALES]:=en}"
: "${P[COPYRIGHT_HOLDER]:=${P[APP_NAME]}}"
: "${P[APPLE_SIGNIN]:=no}"
: "${P[WEB_RUN_PREFIX]:=}"
: "${P[MOBILE_NPM]:=npm}"
: "${P[MOBILE_CAP]:=npx cap}"
: "${P[COMMIT_STYLE]:=one commit per logical change}"
: "${P[TARGETS]:=android,ios}"
: "${P[WELLKNOWN_DIR]:=public/.well-known}"
if [ "${P[APPLE_SIGNIN]}" = yes ]; then
  : "${P[BRIDGE_REGISTER_PLUGINS]:=bridge?.registerPluginInstance(AppleSignInPlugin())}"
  : "${P[ENT_APPLESIGNIN]:=<key>com.apple.developer.applesignin</key>
	<array>
		<string>Default</string>
	</array>}"
else
  : "${P[BRIDGE_REGISTER_PLUGINS]:=// No custom plugins registered (APPLE_SIGNIN=no).}"
  : "${P[ENT_APPLESIGNIN]:=<!-- Sign in with Apple not enabled (APPLE_SIGNIN=no) -->}"
fi

if [ -z "${P[AASA_CALLBACK_COMPONENTS]:-}" ]; then
  comp=""
  IFS=',' read -r -a cb_paths2 <<< "${P[CALLBACK_PATHS]}"
  for p in "${cb_paths2[@]}"; do
    p="${p//[[:space:]]/}"; [ -n "$p" ] || continue
    comp+="          { \"/\": \"${p}\", \"comment\": \"OAuth return: MUST come before the /api exclusion (first match wins)\" },"$'\n'
  done
  P[AASA_CALLBACK_COMPONENTS]="${comp%$'\n'}"
fi

if [ -z "${P[ANDROID_APPLINK_DATA]:-}" ]; then
  data=""
  IFS=',' read -r -a cb_paths <<< "${P[CALLBACK_PATHS]}"
  for p in "${cb_paths[@]}"; do
    p="${p//[[:space:]]/}"; [ -n "$p" ] || continue
    data+="                <data android:scheme=\"https\" android:host=\"${P[PROD_HOST]}\" android:pathPattern=\"${p}\" />"$'\n'
  done
  P[ANDROID_APPLINK_DATA]="${data%$'\n'}"
fi

# Export for awk (prefix avoids clobbering the real environment).
for k in "${!P[@]}"; do export "P_$k=${P[$k]}"; done

TEXT_RE='\.(sh|md|json|ts|js|java|kt|gradle|xml|plist|strings|xcprivacy|entitlements|swift|html|yml|yaml|txt|env|example|properties|snippet|tmpl|rb)$'
is_text() {
  local f="$1" base; base="$(basename "$f")"
  [[ "$f" =~ $TEXT_RE ]] && return 0
  # extension-less script/config files (bin/install, apple-app-site-association, ...)
  [[ "$base" != *.* ]] && grep -Iq . "$f" 2>/dev/null && return 0
  return 1
}

render_one() { # src dst
  local src="$1" dst="$2" tmp
  mkdir -p "$(dirname "$dst")"
  tmp="$(mktemp)"
  if is_text "$src"; then
    if ! awk '
      BEGIN { bad = 0 }
      {
        out = ""; rest = $0
        while (match(rest, /\{\{[A-Z][A-Z0-9_]*\}\}/)) {
          key = substr(rest, RSTART + 2, RLENGTH - 4)
          if (("P_" key) in ENVIRON) val = ENVIRON["P_" key]
          else { printf("UNRESOLVED {{%s}} at %s:%d\n", key, FILENAME, NR) > "/dev/stderr"; bad = 1; val = "" }
          out = out substr(rest, 1, RSTART - 1) val
          rest = substr(rest, RSTART + RLENGTH)
        }
        print out rest
      }
      END { exit bad }
    ' "$src" > "$tmp"; then
      rm -f "$tmp"; echo "render failed for $src" >&2; return 1
    fi
  else
    cp "$src" "$tmp"
  fi
  if [ -e "$dst" ] && ! cmp -s "$tmp" "$dst"; then
    if [ "$FORCE" = 1 ]; then
      cat "$tmp" > "$dst"; echo "OVERWRITE $dst"
    else
      echo "CONFLICT  $dst exists and differs (merge by hand or use --force)"
      CONFLICTS=$((CONFLICTS + 1))
    fi
  elif [ -e "$dst" ]; then
    echo "same      $dst"
  else
    cat "$tmp" > "$dst"; echo "created   $dst"
  fi
  [ -x "$src" ] && chmod +x "$dst" 2>/dev/null || true
  rm -f "$tmp"
}

CONFLICTS=0
if [ -d "$SRC" ]; then
  while IFS= read -r -d '' f; do
    rel="${f#"$SRC"/}"
    render_one "$f" "$DEST/$rel" || exit 1
  done < <(find "$SRC" -type f -print0 | sort -z)
else
  [ -d "$DEST" ] && DEST="$DEST/$(basename "$SRC")"
  render_one "$SRC" "$DEST" || exit 1
fi
[ "$CONFLICTS" -eq 0 ] || exit 3
