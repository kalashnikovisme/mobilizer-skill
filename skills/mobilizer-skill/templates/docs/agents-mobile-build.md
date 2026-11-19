# Building and testing the {{APP_NAME}} mobile apps (rules for AI agents)

The product is a Capacitor shell in `mobile/` around **{{PROD_URL}}** (remote-URL mode).
**Scope exception:** Xcode and the Android SDK cannot run in containers, so native builds run on the
host through the scripts below. Web code is run the way this repo prescribes: `{{WEB_RUN_PREFIX}}` (empty = directly).
Node tooling for `mobile/` runs as `{{MOBILE_NPM}}` / `{{MOBILE_CAP}}` (the scripts already do this).
Use ONLY these scripts — do not improvise ad-hoc build commands.

## One command per scenario
| User says | You run |
|---|---|
| "put it on my Android phone" | `mobile/android/bin/run-wifi` (first time: `bin/install`, then `bin/pair-wifi`) |
| "run it in the iOS simulator" | `mobile/ios/bin/run-simulator` |
| "put it on my iPhone" | `mobile/ios/bin/run-device` (`--free` for a free Apple ID) |
| "build for Google Play" | `mobile/android/bin/release` |
| "send to TestFlight" | `mobile/ios/bin/testflight` (paid team) |
| "new machine" | `mobile/android/bin/install` / `mobile/ios/bin/install` |

If a script fails: read the real error, fix the cause **in the script** (missing tool → fix `bin/install`),
re-run. Never report success without the script's own confirmation line (device launched / artifact path /
screenshot inspected).

## Ask the human only for what needs hands
Give numbered, plain-language steps for: sudo/Apple ID passwords, signing into Xcode (Settings → Accounts →
copy the Team ID), cable + "Trust" + Developer Mode on the iPhone, trusting the developer profile
(Settings → General → VPN & Device Management), Wireless-debugging pairing screen on Android, store consoles.

## Mandatory rules
1. After any change under `mobile/` that affects Android, run `mobile/android/bin/run-wifi` (if a phone is
   paired) **before** reporting the task done. iOS changes: `run-simulator` at minimum.
2. **Mobile fixes must not change web behaviour.** Web changes for the apps are additive and gated by the
   user-agent helper (`{{UA_ANDROID}}` / `{{UA_IOS}}`). Before deploying the web, write down why it is safe for
   browser users; after deploying, verify the website itself. If a fix would cost the web something, stop and ask.
3. No prices, upgrade buttons, pricing links or payment SDK inside the apps (store billing rules); gate every
   new purchase-related UI with the native-app helper.
4. Secrets (keystores, `.p8`, provisioning profiles, `google-services.json`, `ios/local.env`, `local.properties`)
   stay out of git and out of the chat. Check `.gitignore` before committing.
5. Commit style: {{COMMIT_STYLE}}. Do not rewrite history.
6. `npx cap sync android|ios` only — never bare `npx cap sync`.

## Device checklist
Run `references/test-checklist.md` of the `mobilizer-skill` skill (or the copy in `docs/`), report
PASS / FAIL / NOT RUN per line.

Release procedures: `ios-release.md`, `android-release.md`. Store text: `store-listing.md`.
