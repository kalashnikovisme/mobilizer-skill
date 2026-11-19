# iOS release (TestFlight → App Store)

Bundle id **{{APP_ID}}** is permanent once published. iOS builds need macOS + Xcode; on Linux the agent
prepares everything and hands this document to a Mac user.

## Only the Apple account owner can do these (checklist)
1. Join the Apple Developer Program (US$99/year). **Individual** = fast, listed under a personal name.
   **Organization** = needs a D-U-N-S number and legal-entity verification (days to weeks).
2. developer.apple.com → Identifiers → register App ID `{{APP_ID}}` with capabilities **Associated Domains**
   (+ **Sign in with Apple** if `APPLE_SIGNIN=yes`, + Push if used).
3. App Store Connect → Apps → "+" → New App: name, language, bundle id `{{APP_ID}}`, SKU.
4. If Sign in with Apple is used: Keys → "+" → Sign in with Apple → download the `.p8` **once**; put Key ID,
   Team ID and the key into the BACKEND's secret store (never git, never chat).
   If the backend sends email: register the sending domain under Sign in with Apple → Email Sources.
5. `mobile/ios/bin/set-team-id <TEAMID>` → commit → **deploy the web app** → verify
   `curl -s {{PROD_URL}}/.well-known/apple-app-site-association` (200, JSON, contains `<TEAMID>.{{APP_ID}}`).
6. Add testers: App Store Connect → TestFlight (internal testers need an Apple ID invited to the team).

## Agent steps
1. `mobile/ios/bin/install` → fill `TEAM_ID` in `mobile/ios/local.env`.
2. `mobile/ios/bin/run-device` once to verify, then `mobile/ios/bin/testflight`.
3. Processing in App Store Connect takes ~10–30 min; then the build appears in TestFlight.
4. Review submission: fill App Review notes from `store-listing.md`, attach screenshots (6.9" 1320×2868 and
   6.5" 1284×2778), App Privacy answers = `PrivacyInfo.xcprivacy`.

## Review checklist
4.2 not-just-a-website (native offline page, haptics, keyboard/safe-area, camera/mic, deep links, push) ·
3.1.1 no purchase UI · 4.8 Sign in with Apple beside other social logins · 5.1.1(v) in-app account deletion ·
privacy policy URL · demo account for the reviewer.
