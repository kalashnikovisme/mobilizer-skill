---
name: mobilizer-skill
description: 'Turn a working web application into installed, store-ready mobile apps: Android and iOS wrappers built with Capacitor around the live production site, running on a phone/simulator, signed, and uploaded to TestFlight / Google Play. Use when the user says "build a mobile app", "make an Android/iOS app from my site", "собери мобильное приложение", "поставь на телефон", "put it on my phone", or mentions Capacitor, TestFlight, Google Play, App Store, APK/AAB, App Links, Universal Links, assetlinks.json, apple-app-site-association, Sign in with Apple, store listing/review notes, or hiding payments in a native app. Automates toolchain install, builds, device runs, signing and release scripts; asks the human only for what cannot be done from a terminal.'
---

# mobilizer-skill

Guides an existing, deployed web app to: installed on a phone → signed → in TestFlight / Google Play. Default architecture:
**Capacitor in remote-URL mode** (the WebView loads the live site). Do everything that can be automated; ask the human only for
what needs hands (passwords, Apple ID, buttons on the phone, store consoles).

## Runtime and file loading
Resolve every relative path (`references/…`, `templates/…`, `scripts/…`, `VERSION`) against this skill's own base directory
(announced when the skill is invoked). Fallbacks: `~/.claude/skills/mobilizer-skill/`, `~/.codex/skills/mobilizer-skill/`, `skills/mobilizer-skill/`
inside the source repo. **Claude Code**: use the Read tool to load a reference when a phase says to; it is not auto-loaded.
**Codex / Cursor / others**: read the file with whatever file tool you have. Never skip a referenced file; if unreadable, tell the user.
On load, read `VERSION` and print `mobilizer-skill v<version>` first.

## Non-negotiable principles
1. **One command per scenario.** The `bin/` scripts are the only supported path. Do not improvise ad-hoc build commands. If a script fails
   or lacks a capability, **fix/extend the script** (maintenance contract in each header), then re-run.
2. **Report the real result.** No "done" without proof: the script's own success line, the artifact path, the device/simulator launch, or an
   inspected screenshot. Show real errors. Unrun checks are "not run", never "passed".
3. **Human only for what cannot be scripted** (sudo/Apple passwords, Xcode sign-in, cable + "Trust" + Developer Mode, wireless-debugging pairing screen,
   store consoles). Ask with **numbered, plain-language steps** written for a non-developer; one batch at a time. Never type passwords yourself.
4. **Secrets**: keystores, `.p8`, provisioning profiles, `google-services.json`, `local.env`, `local.properties` are gitignored and outside the repo where
   specified; values are never printed to chat or written into repo files. Check and extend `.gitignore` yourself (`references/secrets-and-signing.md`).
5. **Mobile must not break the web.** Web changes are additive and UA-gated; before deploying write a web-safety statement; after deploying verify the
   website itself. If a mobile fix costs the web anything → stop and ask (`references/web-adaptation.md`).
6. **Commit** each logical change separately if the repo does so; never rewrite history; never push/deploy without the repo's rules and the user's consent.
7. **Respect the target repo's rules** (AGENTS.md, CLAUDE.md, docker/dip/mise wrappers, "never run X on production", forbidden files). Web commands run the
   repo's way; native builds (Xcode, Android SDK) are the documented exception and use the scripts. **Node tooling for `mobile/` (npm, Capacitor CLI) also follows
   the repo**: if it forbids host Node (e.g. "always use dip"), set `MOBILE_NPM`/`MOBILE_CAP` in `MOBILE.md` to a wrapper the repo provides (create the smallest
   wrapper in the repo's own style, e.g. `dip mobile-npm` / `dip mobile-cap`, and ask first), never silently run host Node. Our conventions never override the repo's.
   This skill is installed globally; do not vendor it into the target repo unless that repo's rules ask for it.
8. **Idempotent scripts**, tool versions pinned in one place at the top of each script.
9. After meaningful changes under `mobile/`, run `mobile/android/bin/run-wifi` on a paired Android phone **before** reporting readiness
   (iOS: `bin/run-simulator` at minimum).
10. **Nothing product-specific is hardcoded.** All names/domains/ids come from `mobile/MOBILE.md`, rendered into templates.

## Rendering templates
`scripts/render.sh [--params mobile/MOBILE.md] [--force] SRC DEST` substitutes `{{KEY}}` from the ```` ```env ```` block of `MOBILE.md`,
**fails on any unresolved key**, never overwrites a differing file without `--force` (exit 3 = conflict → merge by hand).
Derived keys: `APP_ID_PATH`, `PROD_HOST`, `APP_PASCAL`, `UA_ANDROID`, `UA_IOS`, `ANDROID_APPLINK_DATA`, `BRIDGE_REGISTER_PLUGINS`, `ENT_APPLESIGNIN`.

| Template (`templates/…`) | Destination in the target repo |
|---|---|
| `MOBILE.md` (filled by hand, not rendered) | `mobile/MOBILE.md` |
| `package.json`, `capacitor.config.ts`, `www/offline.html` | `mobile/` |
| `gitignore.snippet` | append missing lines to root `.gitignore` |
| `mobile-README.md` | `mobile/README.md` |
| `android/bin/*` | `mobile/android/bin/` (chmod +x) |
| `android/{app-build.gradle,AndroidManifest.xml,MainActivity.java}` | `mobile/android/app/build.gradle`, `…/src/main/AndroidManifest.xml`, `…/src/main/java/<APP_ID_PATH>/MainActivity.java` |
| `android/store/README.md` | `mobile/android/store/README.md` |
| `ios/bin/*`, `ios/local.env.example` | `mobile/ios/bin/`, `mobile/ios/local.env.example` |
| `ios/{App,AppFree}.entitlements`, `PrivacyInfo.xcprivacy`, `BridgeViewController.swift` | `mobile/ios/App/App/` (rename the Swift file to `<APP_PASCAL>BridgeViewController.swift`) |
| `ios/AppleSignInPlugin.swift` (only if `APPLE_SIGNIN=yes`) | `mobile/ios/App/App/Plugins/` |
| `ios/InfoPlist.strings` | `mobile/ios/App/App/<locale>.lproj/InfoPlist.strings` per locale, **translated** |
| `web/native-app.ts`, `web/use-native-app.ts` | web source tree, following the repo's layout |
| `web/assetlinks.json`, `web/apple-app-site-association` | `WELLKNOWN_DIR` of the web app (read `web/well-known-notes.md`) |
| `docs/*.md` | repo docs location (Phase 8) |

---

## Phase 0 — Discovery and questionnaire
Load `references/discovery.md`. (1) Read the target repo read-only: rules, framework, run/test/deploy conventions, prod URL, auth, payments, SDKs,
permissions, existing `mobile/`. Show a Findings table. (2) Ask all open questions in **one message with options**: app name/slug, **application id
(reverse-DNS; IMMUTABLE after publication — warn and get explicit confirmation)**, prod URL, targets, store accounts (Play US$25; Apple US$99/yr,
Individual vs Organization + D-U-N-S), whose accounts, host OS (**iOS builds only on macOS**; on Linux/Windows do Android and prepare iOS + a Mac handoff),
OAuth providers/callback paths, payments, push, languages, secrets store, brand assets.
(3) Write `mobile/MOBILE.md` (no secrets) from `templates/MOBILE.md`; commit.
**Checkpoint:** user confirmed id + URL + targets. If `mobile/` already has content, treat the task as an update: read it first, don't regenerate over it (an empty directory is a fresh start).
If the production URL cannot be determined from the repo, ask — never guess a domain.

## Phase 1 — Architecture
Default: Capacitor **remote-URL** — `server.url` = prod site, `webDir` an empty placeholder, no web-asset build, so the app never lags the site.
Explain the trade-offs in 5 lines: needs network (offline screen mitigates); updates ship with the site (no store review for web changes);
**App Store 4.2 "just a website" rejection risk**, countered by genuine native features (offline page, haptics, keyboard/safe-area, mic/camera, Sign in with
Apple, deep links, push). Offer a **bundled static build** only if the app has no SSR/server and needs offline, or the owner insists — then the web build
becomes part of the mobile pipeline (more work; say so). Record the decision in `MOBILE.md`.
**Checkpoint:** architecture agreed.

## Phase 2 — Scaffold `mobile/`
Separate dependency tree (`mobile/package.json` + lockfile; use the repo's package manager conventions for the lockfile, npm by default).
If Node must go through a repo wrapper, create/confirm it first (it must run inside `mobile/` and forward `CAP_DEBUG`). Render `package.json`, `capacitor.config.ts`, `www/offline.html`, `mobile-README.md`, `.gitignore` lines; `npm install`; `npx cap add android|ios` for the
targets; add `mobile/assets/` (icon 1024², splash 2732², foreground) and `npx capacitor-assets generate`. Config invariants (already in the template; do not remove):
platform `appendUserAgent` markers (`<App>AndroidApp` / `<App>IosApp`); iOS `contentInset: 'never'`, `backgroundColor`, `Keyboard.resize: 'native'`;
Android `webContentsDebuggingEnabled` only for debug (`CAP_DEBUG=1`); platform differences via `process.argv`; **always `npx cap sync android` /
`npx cap sync ios`, never bare `cap sync`**; **never add the OAuth provider host (e.g. accounts.google.com) to `allowNavigation`** — its absence sends
OAuth to the external browser (Google blocks embedded WebViews).
**Checkpoint:** `git status` clean of secrets; `.gitignore` checked; commit scaffold.

## Phase 3 — Adapt the web app
Load `references/web-adaptation.md` and follow its hard rule. Items: UA helper + hook + server check; hide purchases/prices/pricing redirect/payment SDK
in-app; `viewport-fit=cover` + safe-area + `100dvh`; OAuth via external browser with return through App Links/Universal Links (callback works for both);
popups; offline/network-loss notice; in-app account deletion and Sign in with Apple (4.8) when social logins exist; `/.well-known/assetlinks.json` and
`apple-app-site-association` (static, no redirects, JSON, excluded from middleware, API/OAuth/payment paths excluded).
**Checkpoint:** web-safety statement written → repo tests/lint via the repo's wrapper → deploy per repo rules (ask the user; if the repo forbids agents from deploying
or from touching production, hand the deploy to the human with exact steps and do NOT claim App Links/Universal Links work) → verify the website and
the `.well-known` URLs with `curl`. Native work needing App Links cannot be fully verified before this deploy.

## Phase 4 — Android
Load `references/android.md`. Render the Android templates; **never ask the user to hand-install tools**: run `bin/install` (if it needs sudo, ask the human
to run `! mobile/android/bin/install`). Then `bin/pair-wifi` (human scans a QR) once and `bin/run-wifi` for every cycle. Debug id is `<APP_ID>.debug` and installs next to the
Play build. App Links: append fingerprints (debug keystore of each machine, upload key, **Play App Signing key** from Play Console) with
`scripts/assetlinks-add.sh` — never replace existing entries; deploy web. Release: `bin/make-upload-key` (outside the repo, **remind to back up**),
`bin/release` → `.aab`; **warn loudly when the upload key is missing (unsigned build)**; `versionCode` rises every upload; assets in `android/store/`.
Push (if wanted): FCM, `google-services.json` generated by `bin/google-services` from the repo's secret store (never committed; separate debug/prod configs),
channels in `MainActivity` equal the backend's, permission asked after a value moment.
**Checkpoint:** `run-wifi` printed "Launched …" and the app shows the site; for release, the `.aab` path + signer fingerprint reported.

## Phase 5 — iOS (macOS only)
Load `references/ios.md`. Not on macOS → render the iOS tree, write the Mac handoff (`ios-release.md`), say clearly what was NOT built. On macOS:
`bin/install` → `npx cap add ios` → `bin/configure` → **simulator first** (`bin/run-simulator`: build, launch, screenshot, *open the screenshot and confirm the
site loaded*) — no iPhone or Apple ID needed. Real device: `bin/run-device` (`--free` for a free Apple ID: no Sign in with Apple / Universal Links / push,
`AppFree.entitlements`, 7-day signature — explain). Give the human steps for: Xcode → Settings → Accounts + Team ID, cable + Trust + Developer Mode, trusting the
developer profile. `bin/set-team-id <TEAMID>` then deploy web + `curl` the AASA. `bin/testflight` (paid team): archive → export/upload; tell the user App Store Connect
processing takes ~10–30 min. Print "Launched on the iPhone." only after it actually launched. Owner-only checklist (membership, App ID capabilities, App Store Connect app,
`.p8` key → backend secrets, Email Sources, testers): `ios-release.md`.
**Checkpoint:** simulator screenshot inspected; device/TestFlight status stated exactly.

## Phase 6 — Store listing and review
Load `references/store-compliance.md`. Fill `store-listing.md` (name ≤30, subtitle ≤30, keywords ≤100, descriptions per language, category, age rating, support/
privacy URLs, **App Privacy = `PrivacyInfo.xcprivacy` = Play Data safety**, reviewer notes: demo account, why each permission, "no purchases in the app", how to delete
the account, why it is more than a website). Screenshots: iOS 6.9" 1320×2868 and 6.5" 1284×2778, Play phone/tablet — from simulator/device.
**Checkpoint:** the three privacy answers are consistent; owner reviews the text.

## Phase 7 — Verify on device
Load `references/test-checklist.md` and run it, reporting **PASS / FAIL / NOT RUN** per row with device/OS/build, plus the "web unchanged" rows after any web deploy.
Fix FAILs through scripts/templates (and web changes via Phase 3 rules), re-run the affected rows.

## Phase 8 — Documentation and agent instructions
In the target repo (follow its docs layout and commit style; never create files its rules forbid): `mobile/README.md`; `ios-release.md`, `android-release.md`,
`store-listing.md` under its docs folder; a short `.agents/mobile-build.md` (or the repo's equivalent) from `templates/docs/agents-mobile-build.md`; copy the
checklist as `mobile-test-checklist.md`; link all of them from AGENTS.md (and CLAUDE.md only if that file already exists and is allowed). Update `MOBILE.md` status.
Final report: what exists, what was verified (with evidence), what the human still must do, and what remains unautomated.

## Handoff boundaries (what only humans can do)
sudo passwords · Apple ID sign-in in Xcode · Apple/Google developer enrolment and fees · App Store Connect / Play Console forms · cable/Trust/Developer Mode/wireless
pairing on the phone · downloading the Sign in with Apple `.p8` · backing up the upload keystore · approving production web deploys.
