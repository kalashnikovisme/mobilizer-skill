# Phase 7 — Device checklist

Run on a **real device** where possible (Android over Wi-Fi via `bin/run-wifi`; iPhone via `bin/run-device`; iOS simulator via `bin/run-simulator`
for everything marked [sim]). Report **PASS / FAIL / NOT RUN (reason)** for every line — no summaries like "all good". Attach the iOS screenshot path.
Record the device model, OS version, app build, platform, date in the report. A line you could not run is NOT RUN, never PASS.

| # | Check | Android | iOS |
|---|---|---|---|
| 1 | Cold launch loads the real site (not blank/offline page) [sim] | | |
| 2 | Log in with email/password; session survives app restart [sim] | | |
| 3 | Social login (e.g. Google) opens the EXTERNAL browser and **returns into the app**, logged in | | |
| 4 | Sign in with Apple works and creates/links the account (paid team, device only; skip if not offered) | n/a | |
| 5 | Main user journeys of the product (list 3–5 from Phase 0) complete end to end [sim] | | |
| 6 | Each permission prompt: text is clear and localized; **deny** → app degrades gracefully; **allow** → feature works | | |
| 7 | Launch in **airplane mode** → offline screen (iOS) / sensible error (Android); "Try again" works after reconnect | | |
| 8 | Lose network **mid-use** → banner/notice; recovery after reconnect | | |
| 9 | Keyboard never covers the focused field (login, register, settings, chat/forms); bottom bars stay visible [sim] | | |
| 10 | No overlap with status bar / notch / Dynamic Island / home indicator / gesture bar; landscape not broken (or locked) [sim] | | |
| 11 | **No prices, upgrade/Premium buttons, pricing links, billing portal, payment sheets anywhere**; direct URL to the pricing page redirects away | | |
| 12 | Links to external sites open in the browser; internal deep links (App Link / Universal Link) open in the app | | |
| 13 | Popups / file upload / camera picker / downloads behave | | |
| 14 | Back navigation (Android back button / iOS swipe) behaves; no trap screens | | |
| 15 | Account deletion works in-app and the account is really gone | | |
| 16 | Push permission is requested only after a value moment (if push exists); a test push arrives | | |
| 17 | Rotation / background → foreground / app switcher: state kept, no reload loops | | |
| 18 | Dark mode / large text do not break layout | | |
| 19 | Performance sanity: first paint < ~3 s on Wi-Fi; no jank when scrolling main list | | |

## The web must be unchanged (after any web deploy)
| # | Check | Result |
|---|---|---|
| W1 | Normal desktop browser: home, login, main flow, pricing/payment pages (if any) behave exactly as before | |
| W2 | Mobile browser (not the app): nothing app-specific leaked (no hidden prices, no changed redirects) | |
| W3 | Repo's own web tests/lint pass via the repo's wrapper | |
| W4 | `curl -sI https://HOST/.well-known/assetlinks.json` and `…/apple-app-site-association`: 200, `application/json`, no redirect | |
| W5 | `adb shell pm get-app-links <pkg>` → verified (Android); AASA served by Apple's CDN (iOS) | |

## Report format
```
Device: Pixel 8 / Android 15 | iPhone 15 / iOS 26.1 (sim|device) | build 1.0 (12) | 2026-11-19
1 PASS  2 PASS  3 FAIL — returns to browser, not app (assetlinks has no debug fingerprint)  4 NOT RUN — free Apple ID …
Blockers: …   Fixes made: …   Follow-ups for the owner: …
```
