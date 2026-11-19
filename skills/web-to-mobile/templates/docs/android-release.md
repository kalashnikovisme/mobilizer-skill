# Android release (Google Play)

Owner of the Play Console account: {{COPYRIGHT_HOLDER}}. Application id **{{APP_ID}}** is permanent once published.

## One-time, by the account owner (not automatable)
1. Create a Google Play Console developer account (one-time US$25; identity verification can take days;
   new personal accounts must run a closed test with ≥12 testers for 14 days before production).
2. Create the app: name `{{APP_NAME}}`, default language, "App" / "Free", accept declarations.
3. Complete App content: privacy policy URL, Data safety (must match `store-listing.md` and the iOS
   privacy manifest), content rating questionnaire, target audience, ads declaration, **account deletion**
   URL/in-app path, government/financial/health declarations if applicable.
4. Enrol in **Play App Signing** when uploading the first bundle.

## Per release (agent)
1. `mobile/android/bin/make-upload-key` (once) and **back up** `~/.config/{{APP_SLUG}}/` — losing the upload key
   means a support ticket to Google.
2. `mobile/android/bin/release` → `mobile/android/app/build/outputs/bundle/release/app-release.aab`
   (the script bumps `versionCode`; commit it).
3. Human: Play Console → Test and release → (Internal testing | Closed | Production) → Create release →
   upload the `.aab` → release notes → Review and roll out.
4. First upload only: Play Console → Test and release → **App signing** → copy the *App signing key*
   SHA-256, then append it for package `{{APP_ID}}`:
   `scripts/assetlinks-add.sh {{WELLKNOWN_DIR}}/assetlinks.json {{APP_ID}} <SHA256>` and **deploy the web app**
   — otherwise App Links (OAuth return) fail for Play-installed builds.
5. Debug builds (`{{APP_ID}}.debug`) need this machine's debug-keystore fingerprint
   (`mobile/android/bin/fingerprint debug-keystore`) in `assetlinks.json` for package `{{APP_ID}}.debug`.

## Listing assets
`mobile/android/store/` (icon 512, feature graphic 1024×500, screenshots). Text: `store-listing.md`.

## Push notifications (only if used)
`mobile/android/bin/google-services development|production` generates `google-services.json` from the secret
store (never commit it). Channel ids in `MainActivity` must equal the backend's. Ask for the Android 13+
notification permission after a value moment, not at launch.
