# Phase 6 — Store rules, privacy, review

Rules change. Treat the points below as the **default-safe interpretation**; when a rule matters to a product decision
(e.g. external purchase links), check the current Apple App Review Guidelines / Google Play policies and ask the owner.

## Apple App Store
| Rule | What it means here |
|---|---|
| **4.2 Minimum functionality** ("just a website" rejections) | A pure WebView of a site is the #1 rejection risk of this architecture. Counter it with *real* native value and list it in the review notes: offline screen (`errorPath`), haptics (`@capacitor/haptics`), native keyboard/safe-area handling, camera/microphone, Sign in with Apple, Universal Links, push, share sheet. Aim for ≥3 genuine ones. A site that is only a marketing page or only links out will be rejected. |
| **3.1.1 In-App Purchase** | Digital goods/subscriptions/unlocks in the app must use IAP; no buttons/links/text steering to external purchase (some storefronts allow limited external links — default: hide everywhere, decide with the owner). Hide prices, upgrade UI, pricing links, billing portal; don't load the payment SDK. Exceptions: physical goods, real-world services, person-to-person services, "reader" apps (log-in to content bought elsewhere, with special entitlements). |
| **4.8 Login services** | If the app offers third-party/social login (Google, Facebook…), also offer Sign in with Apple (or an equivalent that meets 4.8's privacy criteria). Email+password only → not required. |
| **5.1.1(v) Account deletion** | If users can create accounts, the app must let them initiate deletion in-app (a web flow reachable from the app is acceptable); revoke Sign in with Apple tokens on deletion. |
| **5.1.1 / 5.1.2 Privacy** | Privacy policy URL in the app & listing; purpose strings for every permission; App Privacy "nutrition labels" accurate and equal to `PrivacyInfo.xcprivacy`; tracking only with ATT. |
| **2.1 Completeness** | Reviewer must be able to use everything: provide a **demo account** (or full sign-in-less access), working backend, no placeholder content. |
| **4.0 / 2.5 Design** | No broken layouts on notch/Dynamic Island, works on iPad if "iPhone+iPad" is selected (set targeted device family deliberately; iPhone-only is simpler). |
| **Export compliance** | `ITSAppUsesNonExemptEncryption=false` for HTTPS-only apps. |
| **Metadata** | Name ≤30, subtitle ≤30, keywords ≤100 chars, screenshots 6.9" (1320×2868) and 6.5" (1284×2778) required; no prices or other platforms' names in screenshots; support URL working. |

## Google Play
| Rule | What it means here |
|---|---|
| **Payments policy** | Digital goods need Play Billing; do not steer users to external payment pages. Same UI hiding as iOS. |
| **Data safety form** | Declare everything collected/shared incl. SDKs (analytics, crash). Must match iOS App Privacy and the privacy policy. |
| **Account deletion** | In-app path **and** a web URL to request deletion, entered in Data safety. |
| **Permissions** | Declare only what the web app uses; sensitive permissions need a justification/video. Notification permission (13+) after a value moment. |
| **Target audience / content rating / ads declaration** | Mandatory questionnaires; answer honestly (UGC, web access, ads). |
| **Testing requirement** | New personal accounts: closed test (currently 12 testers, 14 days) before production access. Org accounts are exempt. Verify in Play Console. |
| **Minimum functionality / repetitive content** | WebView apps that merely repackage a website can be rejected under "Minimum Functionality"; use the same native-value list; Play is more lenient than Apple. |
| **App Links / OAuth** | Google blocks OAuth in embedded WebViews (`disallowed_useragent`) — external browser flow is mandatory (already the default here). |

## Privacy audit (do this once, reuse for both stores)
1. List every data type the **web app** collects (email, name, user id, usage analytics, crash data, audio, photos, location, purchases, contacts…) incl. third-party SDKs.
2. For each: linked to the user? used for tracking? purpose?
3. Fill `PrivacyInfo.xcprivacy`, then `store-listing.md` tables from the same list, then the console forms from `store-listing.md`. Never answer a console from memory.

## Review notes template (also in `templates/docs/store-listing.md`)
Demo credentials · where/why each permission is used · "no purchases / no prices in the app" · how to delete the account ·
what the app does beyond the website (native list) · sign-in methods · any region/network requirements.
Rejections: answer in Resolution Center with specifics, fix, resubmit; never argue generally — point at the implemented native features.

## Screenshots
iOS: simulator (`xcrun simctl io booted screenshot f.png`; pick a 6.9" device type; resize with `sips -z H W`) or device. Play: `adb exec-out screencap -p > f.png`.
Capture per language, realistic data, no prices/PII, status bar clean (`xcrun simctl status_bar booted override --time 9:41 --batteryLevel 100`).
