# {{APP_NAME}} — mobile wrapper (Capacitor)

A thin native shell around the production site **{{PROD_URL}}**. The WebView loads the live site
(*remote-URL mode*): there is no bundled copy of the web app, so `mobile/www/` is an empty
placeholder (plus `offline.html` for iOS) and the wrapper never lags behind the website.

Answers to the setup questionnaire: [`MOBILE.md`](MOBILE.md). Targets: `{{TARGETS}}`.

## Where things live

| Path | What |
|---|---|
| `capacitor.config.ts` | app id, server URL, user-agent markers `{{UA_ANDROID}}` / `{{UA_IOS}}`, platform differences |
| `assets/` | `icon.png` (1024²), `icon-foreground.png`, `splash.png` (2732²) → `npm run assets` |
| `android/bin/` | **the only supported Android workflows** (see below) |
| `ios/bin/` | **the only supported iOS workflows** (macOS only) |
| `android/store/` | Google Play listing assets |
| `~/.config/{{APP_SLUG}}/` | upload keystore + properties — **outside the repo, back them up** |

## Android (any OS with a package manager)

```
mobile/android/bin/install       # JDK + Android SDK + local.properties (may need your sudo password)
mobile/android/bin/pair-wifi     # once: pair the phone by QR (Wireless debugging)
mobile/android/bin/run-wifi      # build debug APK ({{APP_ID}}.debug), install, launch
mobile/android/bin/make-upload-key   # once: create the upload keystore outside the repo
mobile/android/bin/release       # signed .aab for Google Play (bumps versionCode)
mobile/android/bin/fingerprint apk|debug-keystore|upload-key   # SHA-256 for assetlinks.json
```

## iOS (macOS only)

```
mobile/ios/bin/install           # Xcode checks, Node, npm ci, creates ios/local.env
mobile/ios/bin/configure         # once, after `npx cap add ios`: wire the Xcode project
mobile/ios/bin/run-simulator     # no iPhone / Apple ID needed; saves a screenshot
mobile/ios/bin/run-device [--free]   # real iPhone ({{APP_ID}}.dev)
mobile/ios/bin/set-team-id ABCDE12345   # paid team: Universal Links file
mobile/ios/bin/testflight        # archive + upload (paid team)
```

## Rules

- **Always** `npx cap sync android` / `npx cap sync ios`; **never** a bare `npx cap sync`.
- If a script fails because a tool is missing, **fix the script** (maintenance contract in its header).
- Never commit keystores, `.p8`, provisioning profiles, `google-services.json`, `ios/local.env`,
  `android/local.properties`. They are gitignored; secrets are never printed or pasted into chat.
- Mobile fixes must not change the website's behaviour (see `.agents/mobile-build.md`).
- Release procedures: see the `*-release.md` docs; store text: `store-listing.md`.
