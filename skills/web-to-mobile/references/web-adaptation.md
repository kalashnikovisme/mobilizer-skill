# Phase 3 — Adapting the web app (additive, never breaking the web)

## The hard rule
Every web change made for the apps must be **additive** (new files, new gated branches, new static files) and must
leave the behaviour for ordinary browsers byte-for-byte equivalent where possible.

Before deploying any web change, write a short **web-safety statement** in the conversation (and the commit body):
> "Web users are unaffected because: <the only code path that changes is behind `nativeAppPlatform(ua) !== null` /
> a new static file / a new route nobody links to>. Verified by: <test or manual check>."

After deploying, **verify the website itself** (load home, log in with a normal browser, open a pricing/payment page
if one exists, run the repo's web tests), not only the app. If a mobile fix would cost the web something
(removing a feature, changing a default, a redirect for everyone) → **stop and ask the user**.
Deploying follows the repo's own deploy rules (e.g. an installed deploy skill); never improvise production commands,
and respect "do not run X against production" rules.

## 1. Detect "I'm inside the app"
Render `templates/web/native-app.ts` (UA markers = `UA_ANDROID` / `UA_IOS`, same strings as `capacitor.config.ts`) into the
web source tree following the repo's layout (e.g. `src/shared/lib/`, `lib/`, `app/lib/`). Keep both marker lists in sync —
add a comment in both files pointing at each other.
- **Client hook**: `templates/web/use-native-app.ts` (React). Returns "not native" during SSR/hydration so server HTML is
  identical for web and app (no hydration mismatch). Other frameworks: same idea, evaluate `navigator.userAgent` after mount.
- **Server/middleware**: `nativeAppPlatform(request.headers.get('user-agent'))`. Any server-side gating must `Vary: User-Agent`
  if the response is cached by a CDN, or be applied only to uncacheable routes (redirects of pricing pages).

## 2. Payments (Google Play Billing / App Store 3.1.1)
Digital goods/subscriptions inside the app must use the store's billing; the app must not steer users to external payment.
Inside the app (UA marker present):
- hide prices, plan names with prices, "Upgrade/Go Premium" buttons, links to pricing/checkout/billing portal,
  subscription management, promo-code fields, "buy on our website" text;
- do not initialise the payment SDK (Stripe.js, Paddle.js, ...) — no network calls to the processor;
- server: redirect pricing/checkout pages to a neutral page (e.g. home) **only when the UA marker is present**;
- paywalls: show neutral wording ("Available with <plan>") + a link back, never a link out;
- anything *new* involving purchases is gated with `useIsNativeApp()` from day one;
- content bought on the website may still be *used* after sign-in (no mention of how to buy).
If the product has no payments → say so in the review notes and still keep the gate for the future.
Physical goods, real-world services and some B2B/reader-app cases have exceptions — see store-compliance.md; when unsure ask the owner.

## 3. Layout: safe areas and keyboard
- `<meta name="viewport" content="..., viewport-fit=cover">` (Next.js: `export const viewport = { viewportFit: 'cover' }`).
- Pad fixed headers/footers with `env(safe-area-inset-top|bottom|left|right)`; this is a no-op on desktop browsers.
- Use `100dvh` (not `100vh`) for full-height layouts; with `Keyboard.resize: 'native'` (iOS) the WebView shrinks when the
  keyboard opens, so bottom bars and the focused field stay visible. Check every form screen (login, register, settings, chat).
- Disable accidental zoom/overscroll bounce only if it harms the UX, and only for the app (UA-gated CSS class on `<html>`).
- Text-size, tap targets ≥ 44px, `-webkit-tap-highlight-color`, no hover-only UI.

## 4. OAuth (Google etc.) and returning to the app
Google (and some others) **block OAuth inside embedded WebViews**. The Capacitor config deliberately does NOT list the
provider host in `server.allowNavigation`, so the shell opens it in the external browser/Custom Tab. The return trip:
- **Android**: the callback URL on your domain is an **App Link** (`autoVerify` intent-filter in the manifest, generated from
  `CALLBACK_PATHS`; verified through `/.well-known/assetlinks.json`). `MainActivity.onNewIntent` loads it inside the WebView.
- **iOS**: **Universal Links** (Associated Domains entitlement + `apple-app-site-association`). The callback route must work
  both in a normal browser (website) and when opened by the app.
- The callback page must work if opened first in the *external* browser (session ends up there, not in the app) → design the
  flow so the **final redirect that sets the session happens inside the app's WebView** (e.g. the provider redirects to the
  App Link; the web app exchanges the code in that WebView). If the repo's flow uses a token handoff, keep it; do not redesign
  auth without asking.
- The callback may be an **API route** (e.g. `/api/auth/<provider>/callback`) rather than a page; that is fine, but then it must be listed in `CALLBACK_PATHS`,
  and in the AASA it must appear **before** the `/api/*` exclusion (components are matched in order, first match wins — the template renders callbacks first).
- **iOS gotcha:** Universal Links are generally NOT triggered by a server-side redirect inside Safari; they open the app when the user *taps* a link.
  If the OAuth return is a plain 302 to your domain, Safari may just show the page. Options: an interstitial page with a "Return to the app" button
  (user tap → Universal Link), or `@capacitor/browser` (SFSafariViewController / ASWebAuthenticationSession) with a custom URL scheme or the same App Link.
  Verify on a real device; the simulator is unreliable for this. Android App Links do handle the redirect.
- Add `CALLBACK_PATHS` for every locale prefix (`/en/auth/callback,/ru/auth/callback`).
- iOS: if any social login exists, also offer **Sign in with Apple** (4.8) — native plugin `AppleSignInPlugin` (template) +
  backend verification of the identity token (signature, `aud` = bundle id, nonce hash). Show the Apple button only when
  `useIsIosApp()` (or on web too if the product wants — ask).

## 5. Popups (checkout, 3-D Secure, Google Pay)
`window.open` is dropped by a bare Android WebView. The `MainActivity` template adds popup support. If payments are hidden in
the app this matters less, but other embeds (OAuth in popups, help widgets) may rely on it. iOS WKWebView handles popups natively
for user-initiated `window.open`.

## 6. Offline / network loss
- Launch without network: iOS shows `www/offline.html` (`server.errorPath`, iOS-only by default); give Android parity only after
  testing (set the flag for Android in `capacitor.config.ts` deliberately).
- Network lost mid-use: add a small banner/page (UA-gated or generic) listening to `online`/`offline` events, and a retry action.
  Keep it additive; generic banners that also show on web are a web change → get approval.

## 7. Account deletion and Sign in with Apple revocation
Apple 5.1.1(v) and Google Play require in-app account deletion (and a web URL for Play). If missing, **propose** it as web work
(new route + backend endpoint, also revoking Sign in with Apple tokens); do not silently build large features — get the owner's go-ahead.

## 8. `/.well-known` files
Render `templates/web/assetlinks.json` and `templates/web/apple-app-site-association` — see `templates/web/well-known-notes.md`
(placement per framework, headers, middleware exclusion). Key points: static files, **no redirects**, `Content-Type: application/json`,
excluded from middleware matcher, AASA excludes API/OAuth/payment paths. They work **only after the web app is deployed**.
Verify:
```
curl -sI https://HOST/.well-known/assetlinks.json | head -5
curl -sI https://HOST/.well-known/apple-app-site-association | head -5   # 200 + application/json, no Location header
curl -s "https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://HOST&relation=delegate_permission/common.handle_all_urls"
curl -s https://app-site-association.cdn-apple.com/a/v1/HOST            # what Apple's CDN has cached
```

Middleware in Next.js/Express etc.: the usual matcher excludes only static assets by extension; `apple-app-site-association` has none, and `.json` is often not excluded —
add `\\.well-known` to the negative lookahead (or equivalent) and re-test both URLs.

## 9. Checklist before the web deploy
- [ ] Web-safety statement written.
- [ ] Only additive changes; gated by UA or brand-new static files/routes.
- [ ] Middleware matcher excludes `.well-known`.
- [ ] Repo tests/lint (via the repo's own wrapper) pass.
- [ ] After deploy: website smoke check + `.well-known` curls + (app) device check.
