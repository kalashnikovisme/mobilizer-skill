# Phase 5 — iOS (macOS only)

iOS builds need macOS + Xcode. On Linux/Windows: still do Phases 2–3 and render the iOS tree; then produce the Mac handoff
(`docs/…/ios-release.md` + a runnable prompt/steps: "install Xcode → `mobile/ios/bin/install` → `bin/run-simulator`"). Do not pretend to build.
All work goes through `mobile/ios/bin/*`; fix the script, not the situation (MAINTENANCE CONTRACT in `bin/install`).

## 1. Scaffold
```
cd mobile && npm ci && npx cap add ios            # Capacitor 8 uses Swift Package Manager (CapApp-SPM)
```
Render: `templates/ios/bin/*` → `ios/bin/` · `local.env.example` → `ios/local.env.example` · `App.entitlements`, `AppFree.entitlements`,
`PrivacyInfo.xcprivacy`, `BridgeViewController.swift` → `ios/App/App/` (rename `…BridgeViewController.swift` is already named by `APP_PASCAL`) ·
`AppleSignInPlugin.swift` → `ios/App/App/Plugins/` (only if `APPLE_SIGNIN=yes`) · `InfoPlist.strings` → `ios/App/App/<locale>.lproj/InfoPlist.strings`
for each locale, **translated** and trimmed to the permissions the web app really triggers.
Then run `mobile/ios/bin/configure` once (Info.plist keys, Xcode project references, bundle id, display name, entitlements, storyboard class).
Review `git diff` of `project.pbxproj`; commit as its own commit.

## 2. Toolchain: `bin/install`
Checks macOS, free disk, Xcode (`xcodebuild -version`), license, active developer dir, iOS runtime (`xcodebuild -downloadPlatform iOS`),
Homebrew, Node ≥ 20, creates `ios/local.env`, `npm ci`. Steps needing hands are printed as numbered instructions:
> 1. App Store → search "Xcode" → Get (≈10 GB). 2. Open Xcode once, accept the license. 3. In Terminal run `sudo xcodebuild -license accept`
> (type your Mac password; nothing shows while typing). 4. Tell me when done.
Recent Apple rules require uploads built with a current Xcode/SDK — if upload is rejected for SDK age, update Xcode.

## 3. Simulator — the default, needs no iPhone and no Apple ID: `bin/run-simulator`
`cap sync ios` → boot simulator + open Simulator.app → `xcodebuild … -destination "id=$SIM" -derivedDataPath ios/build CODE_SIGNING_ALLOWED=NO`
→ `simctl install` → `simctl launch` → `simctl io … screenshot`. The script checks the site is reachable first, then saves
`ios/build/simulator.png`. **The agent must open the screenshot and confirm the real page is visible** (not white, not the offline page).
Simulator caveats: microphone = Mac mic; no push, no Sign in with Apple login completion on some versions; Universal Links are flaky — test those on a device.
First build downloads Swift packages (slow). Sim name via `SIMULATOR=` in `ios/local.env`.

## 4. Real iPhone: `bin/run-device [--free]`
Human steps (give them exactly like this, one at a time if the user is unsure):
> 1. Xcode → Settings → Accounts → "+" → Apple ID → sign in. Click your team, copy **Team ID** (10 characters), tell me (I put it in `mobile/ios/local.env`).
> 2. Plug the iPhone into the Mac with a cable, unlock it, tap **Trust**, enter the passcode.
> 3. iPhone: Settings → Privacy & Security → **Developer Mode** → On → phone restarts → confirm.
> 4. After the first install: Settings → General → **VPN & Device Management** → your Apple ID → **Trust**.
> 5. (Optional, no cable later) Xcode → Window → Devices and Simulators → select iPhone → *Connect via network*.
Free Apple ID (`--free`, uses `AppFree.entitlements`): **no** Sign in with Apple, Universal Links, push (capabilities need a paid team);
bundle id `<APP_ID>.dev` (explicit, per-account unique — may need a different suffix if taken); the profile **expires after 7 days** (just re-run);
max 3 apps per device. Say all this to the user once.
The script prints "Launched on the iPhone." only after `devicectl` succeeded; otherwise show the real error (signing errors → fix account/team; "no iPhone found" → steps above).

## 5. Team ID, Universal Links: `bin/set-team-id <TEAMID>`
Writes `TEAMID.<APP_ID>` into the AASA file under `WELLKNOWN_DIR` and `local.env`. Then **commit → deploy web → verify**
`curl -s https://HOST/.well-known/apple-app-site-association` (200, JSON, contains the ID). Apple's CDN caches the file (can take up to ~48 h after
first publication): check `https://app-site-association.cdn-apple.com/a/v1/HOST`. For development use the `applinks:HOST?mode=developer` entitlement on a device with Developer Mode.

## 6. Info.plist / privacy / entitlements
- Usage strings (`NSMicrophoneUsageDescription`, `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, …) in `<locale>.lproj/InfoPlist.strings`: explain *why*, per language; only permissions actually used.
- `ITSAppUsesNonExemptEncryption=false` when the app uses only HTTPS/system crypto (avoids the export-compliance prompt per build).
- `PrivacyInfo.xcprivacy` = exactly what you declare in App Privacy (and Play Data safety). Audit the web app's SDKs; third-party SDK manifests ship with their packages.
- `App.entitlements`: `com.apple.developer.associated-domains` = `applinks:HOST`; `com.apple.developer.applesignin` when `APPLE_SIGNIN=yes`. `AppFree.entitlements` is empty.
- Display name via `APP_DISPLAY_NAME` build setting; dev builds append " Dev".

## 7. TestFlight: `bin/testflight` (paid team only)
`cap sync ios` → `xcodebuild archive` (Release, `generic/platform=iOS`, automatic signing, `CURRENT_PROJECT_VERSION=$(date +%y%m%d%H%M)`) →
`xcodebuild -exportArchive` with `ExportOptions.plist` (`method=app-store-connect`, `destination=upload`). Success line prints only after export/upload succeeds.
Tell the user: processing in App Store Connect takes **~10–30 minutes** (sometimes longer; an email arrives), then the build shows under TestFlight → add testers.
`MARKETING_VERSION` (user-facing 1.0.0) is changed in Xcode project settings per release; the build number is automatic.

## 8. What only the Apple account owner can do (guide with a checklist)
Apple Developer membership · register App ID with capabilities (Associated Domains, Sign in with Apple, Push) · create the app in App Store Connect ·
Sign in with Apple `.p8` key (download once → backend secrets, never repo/chat) · Email Sources registration for Hide My Email relay (if the backend emails users) ·
add TestFlight testers · submit for review. Full list: `docs/…/ios-release.md`.

## 9. Common failures
| Symptom | Fix |
|---|---|
| `Signing requires a development team` | `TEAM_ID` empty / not signed in to Xcode |
| `No profiles for '<id>' were found` / capability errors | free team + paid entitlements → use `--free`; paid team → register App ID capabilities |
| `The bundle identifier … is not available` | free-account bundle ids are global; change the `.dev` suffix in the script |
| Build OK, white screen in simulator | no network from Mac / site down / ATS; open the screenshot; check `curl PROD_URL` |
| `devicectl` cannot find the phone | locked, not trusted, Developer Mode off, or different network |
| Archive fails on `CODE_SIGN_ENTITLEMENTS` file missing | re-run `bin/configure`; files must exist under `ios/App/App/` |
