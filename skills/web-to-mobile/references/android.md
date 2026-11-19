# Phase 4 — Android

All Android work goes through `mobile/android/bin/*` (rendered from `templates/android/bin`). If a script cannot do something
the task needs, **extend the script**, then run it. Never leave the user with a manual workaround.

## 1. Scaffold (done in Phase 2; recap)
```
cd mobile && npm ci && npx cap add android
```
Then render over the generated project (keep Capacitor's other files):
`templates/android/app-build.gradle` → `android/app/build.gradle` · `templates/android/AndroidManifest.xml` →
`android/app/src/main/AndroidManifest.xml` (trim permissions to what the web app uses) · `templates/android/MainActivity.java` →
`android/app/src/main/java/<APP_ID_PATH>/MainActivity.java` · `templates/android/bin/*` → `android/bin/` · `templates/android/store/` → `android/store/`.
If `cap add` produced different content than the templates assume (newer Capacitor), merge instead of overwriting.
Icon/splash: `mobile/assets/icon.png` (1024²) + `splash.png` (2732²) → `npm run assets` (`@capacitor/assets`).
Notification small icon (push only): monochrome white-on-transparent vector `ic_stat_<app>` + `notification_accent` colour.

## 2. Toolchain: `bin/install`
Idempotent. Installs a JDK (pacman/apt/brew), Android cmdline-tools, platform-tools, platform for `compileSdkVersion` from
`variables.gradle`, build-tools, accepts licenses, writes `local.properties`, then verifies with `assembleDebug`.
- Versions live at the top of the script only (`JDK_MAJOR`, `BUILD_TOOLS`, `CMDLINE_TOOLS_BUILD`). When Capacitor bumps
  `compileSdkVersion`, bump `BUILD_TOOLS` there too. If the cmdline-tools download 404s, update `CMDLINE_TOOLS_BUILD`
  from https://developer.android.com/studio#command-line-tools-only.
- **MAINTENANCE CONTRACT** (also in the script header): a build that fails on a missing tool is a bug in `bin/install`. Fix the script.
- sudo: the agent never types a password. If the script prints the handoff message, ask the human:
  > 1. Open a terminal in the project folder. 2. Run `mobile/android/bin/install` (Claude Code: type `! mobile/android/bin/install`).
  > 3. Enter your computer password when asked. 4. Tell me when it finishes.
- Android Studio is not needed. Windows: use WSL2.

## 3. Device over Wi-Fi: `bin/pair-wifi` once, `bin/run-wifi` always
Pairing needs the human (phone in hand), same Wi-Fi as the computer:
> 1. On the phone: Settings → About phone → tap *Build number* 7 times (Developer options appear).
> 2. Settings → Developer options → **Wireless debugging** → ON.
> 3. I will show a QR code in the terminal; tap *Pair device with QR code* and scan it. (Alternative: *Pair device with pairing code* and send me the `IP:port` and 6-digit code.)

`run-wifi` finds `_adb-tls-connect._tcp`, runs `CAP_DEBUG=1 npx cap sync android`, `assembleDebug`, installs `<APP_ID>.debug`,
launches and checks the process is alive. The debug id suffix lets it live next to the Play build (which is signed by Google's key).
If no device is paired: ask for the pairing screen; do not skip the check and claim success.
**After any significant change under `mobile/`, run `run-wifi` before reporting done** (when a phone is paired).
Router blocks mDNS? use the manual `adb pair ip:port code` + `adb connect ip:port` flow.

## 4. App Links and fingerprints (OAuth return, deep links)
`assetlinks.json` needs **every signing identity that will run the app**, as separate fingerprints (and, per package, separate entries):

| Who signs | Package in assetlinks | Get the fingerprint |
|---|---|---|
| Debug keystore of each dev machine (auto-generated, differs per machine; may live in `~/.config/.android/` or `~/.android/`) | `<APP_ID>.debug` | `bin/fingerprint debug-keystore` or `bin/fingerprint apk` |
| Your upload key | `<APP_ID>` (only matters for sideloaded release APKs) | `bin/fingerprint upload-key` |
| **Play App Signing key** (Google re-signs what you upload; this is what store users run) | `<APP_ID>` | Play Console → Test and release → **App signing** → *App signing key certificate* SHA-256 |

Append, never replace: `scripts/assetlinks-add.sh <wellknown>/assetlinks.json <package> <SHA256>` (idempotent, keeps existing entries).
Changes take effect only after the **web app is deployed**. Verify on the phone:
`adb shell pm get-app-links <package>` (state `verified`) and `adb shell pm verify-app-links --re-verify <package>`.
Symptom of a missing fingerprint: no error, just an "Open with…" chooser or the callback staying in the browser.

## 5. Release: `bin/make-upload-key`, `bin/release`
- Upload keystore + `upload-keystore.properties` live in `~/.config/<APP_SLUG>/` — **outside the repo**. Remind the user to back
  them up (password manager / encrypted storage). Losing the upload key = support request to Google. Never print the passwords.
- `bin/release` refuses to build without the properties file (Gradle would otherwise silently produce an **unsigned** bundle that
  Play rejects). `ALLOW_UNSIGNED=1` exists for CI dry runs only. **Always warn loudly when signing is missing.**
- `versionCode` must increase on every upload; `bin/release` bumps it in `app/build.gradle` (commit it). `versionName` is the human version.
- Output: `app/build/outputs/bundle/release/app-release.aab`; the script prints the signer SHA-256.
- Target API: Play requires a recent `targetSdkVersion` (the one Capacitor ships is normally compliant) — check the current rule in Play Console.
- Listing assets: `mobile/android/store/` (512 icon, 1024×500 feature graphic, ≥2 phone screenshots).
- Human steps and console checklist: `docs/…/android-release.md`. New personal Play accounts must complete a closed test
  (currently 12 testers × 14 days) before production — warn early, it dominates the schedule. Verify the current policy in Play Console.

## 6. Push notifications (only if requested)
- Plugin `@capacitor/push-notifications`; Firebase project → Android apps for **both** `<APP_ID>` and `<APP_ID>.debug` (or a separate dev project).
- `google-services.json` is **never committed**: `bin/google-services development|production` writes it from the repo's secret store
  (SOPS/1Password/file/custom — set in MOBILE.md). Debug builds need the config containing the `.debug` package.
- Notification channels are created in `MainActivity` (snippet in the template) and their ids **must equal** the backend's `channel_id`s.
- Android 13+: ask for `POST_NOTIFICATIONS` after a moment of value (e.g. after the first completed task), never at launch.
- The web layer drives the plugin through `window.Capacitor.Plugins.PushNotifications`; in remote-URL mode no JS bundle ships with the app,
  so guard calls with the UA helper.

## 7. Common failures
| Symptom | Cause / fix |
|---|---|
| `SDK location not found` | `local.properties` missing → run `bin/install` |
| `Unsupported class file major version` / Gradle JDK error | wrong JDK → `bin/install` rewrites `~/.gradle/gradle.properties` |
| `No matching client found for package name …debug` | wrong `google-services.json` env → `bin/google-services development` |
| White screen in app, site fine in browser | site blocks the UA / CSP `frame-ancestors`/ cookies `SameSite`; check `chrome://inspect` (debug sync only) |
| Login via Google loops | missing fingerprint or callback path not in `CALLBACK_PATHS`/`assetlinks` not deployed |
| Install fails `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | signed by a different key than the installed copy → use the `.debug` id / uninstall |
