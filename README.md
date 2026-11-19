# web-to-mobile

An agent skill (Claude Code, Codex, Cursor, …) that takes a **working, deployed web app** to **installed on a phone → signed →
in TestFlight / Google Play**. It builds and configures everything that can be automated and asks the human only for what needs
hands (passwords, Apple ID, buttons on the phone, store consoles).

Default architecture: **Capacitor in remote-URL mode** — the app's WebView loads your live production site, so the mobile shell never
lags behind the website.

## What it does

| Phase | Result |
|---|---|
| 0 Questionnaire | inspects your repo, asks once, saves answers (no secrets) to `mobile/MOBILE.md` |
| 1 Architecture | remote-URL Capacitor; trade-offs and App Store 4.2 risk explained |
| 2 Scaffold | `mobile/` with config, assets, `.gitignore` for secrets |
| 3 Web adaptation | additive, UA-gated changes: hide payments, safe areas, OAuth via external browser + App Links / Universal Links, `.well-known` files — web must not change |
| 4 Android | `bin/install`, `pair-wifi`, `run-wifi`, `make-upload-key`, `release` (.aab), `fingerprint`, push helpers |
| 5 iOS (macOS) | `bin/install`, `configure`, `run-simulator` (no iPhone/Apple ID), `run-device [--free]`, `set-team-id`, `testflight` |
| 6 Store listing | listing template, privacy answers consistent with `PrivacyInfo.xcprivacy`, reviewer notes, screenshot sizes |
| 7 Device checklist | PASS/FAIL/NOT RUN per row, plus "web unchanged" checks |
| 8 Docs | `mobile/README.md`, release docs, short agent rules linked from AGENTS.md |

## Install

**Claude Code (plugin marketplace)**
```
/plugin marketplace add <path-or-git-url-of-this-repo>
/plugin install web-to-mobile
```
**Manual (Claude Code / Codex)**
```
cp -R skills/web-to-mobile ~/.claude/skills/web-to-mobile
cp -R skills/web-to-mobile ~/.codex/skills/web-to-mobile
```
**Other agents:** point the agent at `skills/web-to-mobile/SKILL.md`.

Then, in your web app's repository, ask: *"turn this web app into Android and iOS apps"* / *"собери мобильное приложение"*.

## Requirements
- Android: Linux/macOS (Windows via WSL2); the scripts install JDK + Android SDK (Android Studio not needed).
- iOS: **macOS with Xcode only**. On Linux the skill prepares iOS and writes a Mac handoff.
- Store accounts: Google Play Console (US$25 once), Apple Developer Program (US$99/year; Individual or Organization with D-U-N-S).

## Layout
```
skills/web-to-mobile/
  SKILL.md  VERSION  CHANGELOG.md
  references/   discovery · web-adaptation · android · ios · store-compliance · secrets-and-signing · test-checklist
  templates/    parameterised files rendered into the target repo ({{KEY}} from mobile/MOBILE.md)
  scripts/      render.sh · assetlinks-add.sh · selftest.sh
```

## Status / caveats
Android scripts and the skill tooling are covered by `scripts/selftest.sh` (render, syntax, XML/JSON). **iOS scripts have not yet been executed on
a Mac** and `ios/bin/configure` (Xcode project wiring via the `xcodeproj` gem) in particular needs its first real run; per the maintenance
contract, fix the scripts when something breaks. Store policies change — the skill points to the current rules but you must verify them.
