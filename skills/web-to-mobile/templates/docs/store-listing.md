# Store listing — {{APP_NAME}} (source of truth for App Store Connect and Google Play)

Fill every field; keep the limits. One column per language in `LOCALES` ({{LOCALES}}).

## Metadata
| Field | Limit | Text |
|---|---|---|
| App Store name | ≤30 chars | |
| Subtitle | ≤30 chars | |
| Keywords | ≤100 chars total, comma-separated, no spaces after commas, don't repeat the name | |
| Promotional text (iOS) | ≤170 | |
| Play short description | ≤80 | |
| Description (App Store ≤4000, Play full ≤4000) | | |
| Primary / secondary category | | |
| Support URL | | |
| Privacy policy URL | | |
| Marketing URL | optional | |
| Copyright | | © YEAR {{COPYRIGHT_HOLDER}} |

## Age rating
Answer the questionnaires honestly (UGC? web browsing? gambling? medical?). Record result: iOS ____ / Play ____.

## App Privacy / Data safety (MUST equal `mobile/ios/App/App/PrivacyInfo.xcprivacy` and each other)
| Data type | Collected? | Linked to user | Used for tracking | Purpose |
|---|---|---|---|---|
| Email | | | | |
| Name | | | | |
| User ID | | | | |
| Usage / analytics | | | | |
| Crash data | | | | |
| Audio / photos / location | | | | |
Third-party SDKs and what they collect: ____. Data deletion: in-app path ____ and web URL ____.
Export compliance: HTTPS only → `ITSAppUsesNonExemptEncryption=false`.

## Notes for the reviewer (paste into "App Review Information → Notes")
- Demo account: ____ / ____ (a dedicated production reviewer account; never a real user's).
- Why microphone / camera / notifications are requested and where to trigger them: ____
- The app contains no purchases, prices or links to buy (payments are hidden inside the app).
- Account deletion: Settings → ____ → Delete account.
- How the app is more than a website (guideline 4.2): offline screen, haptics, native keyboard/safe-area handling,
  Sign in with Apple, deep links/Universal Links, push, device permissions — list what is actually implemented.
- Sign-in methods offered: ____.

## Screenshots
| Store | Size | Notes |
|---|---|---|
| iOS 6.9" | 1320×2868 (required) | simulator "iPhone 17 Pro Max"-class device, or a real iPhone |
| iOS 6.5" | 1284×2778 | |
| Play phone | 16:9 / 9:16, 320–3840 px per side, 2–8 images | `adb exec-out screencap -p` |
| Play tablet 7"/10" | optional | |
Capture: simulator `xcrun simctl io booted screenshot f.png` (resize to the exact size) or device. No prices, no personal data.
