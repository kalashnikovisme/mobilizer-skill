# Mobile app: questionnaire answers

Written by the `web-to-mobile` skill (Phase 0). **No secrets in this file** — it is
committed. The fenced `env` block below is machine-read by the skill's
`scripts/render.sh`; keep the `KEY=VALUE` format. Edit values here, then re-render.

```env
# --- identity ---------------------------------------------------------------
APP_NAME=                # display name on the home screen, e.g. Acme
APP_SLUG=                # lowercase [a-z0-9-], e.g. acme (used for ~/.config/<slug>/ and file names)
APP_ID=                  # reverse-DNS, e.g. com.acme.app  -- IMMUTABLE after the first store upload
PROD_URL=                # https://acme.com  (no path, no trailing slash)
BRAND_COLOR=#FFFFFF      # background behind the page until first paint (match the web theme-color)
LOCALES=en               # comma list of UI languages, e.g. en,ru (usage strings, listing text)
COPYRIGHT_HOLDER=        # legal owner shown in store listings

# --- web integration --------------------------------------------------------
CALLBACK_PATHS=/auth/callback    # OAuth callback path(s) that must reopen the app, comma list
                                 # (e.g. /en/auth/callback,/ru/auth/callback for locale-prefixed routes)
WELLKNOWN_DIR=public/.well-known # where the web app serves /.well-known/* from (repo-relative)
APPLE_SIGNIN=no          # yes if the web app has other social logins (Google...) -> Apple requires it (4.8)
# UA_ANDROID=AcmeAndroidApp      # optional overrides; default <AppName>AndroidApp / <AppName>IosApp
# UA_IOS=AcmeIosApp

# --- targets and accounts ---------------------------------------------------
TARGETS=android,ios      # android | ios | android,ios
HOST_OS=                 # linux | macos | windows  (iOS builds only on macos)
ACCOUNT_OWNER=           # product-owner | me   (whose Play / Apple accounts publish this)
PLAY_ACCOUNT=            # none | have | pending
APPLE_ACCOUNT=           # none | free-apple-id | individual | organization(D-U-N-S)

# --- secrets store (VALUES NEVER GO HERE) -------------------------------------
SECRETS_STORE=none       # none | sops | op (1Password) | file | custom
SECRETS_REF_DEV=         # where google-services.json for debug lives (path / op:// ref / secret name)
SECRETS_REF_PROD=        # same for release

# --- repo conventions discovered in Phase 0 -----------------------------------
MOBILE_NPM=npm           # how Node tooling for mobile/ runs; if the repo forbids host Node use its wrapper, e.g. "dip mobile-npm"
MOBILE_CAP=npx cap       # likewise for the Capacitor CLI, e.g. "dip mobile-cap" (wrapper must forward CAP_DEBUG)
WEB_RUN_PREFIX=          # how this repo runs web commands, e.g. "dip", "docker compose run web", "mise exec --", "" (none)
COMMIT_STYLE=            # e.g. "separate commit per logical change", "conventional commits"
```

## Decisions

| Topic | Decision | Date |
|---|---|---|
| Architecture | Capacitor remote-URL (WebView loads `PROD_URL`) | |
| Payments in app | hidden (UA marker) / none exist | |
| Push notifications | yes / no | |
| Sign in with Apple needed | yes (other social logins exist) / no | |

## Status

- [ ] Phase 1 architecture chosen
- [ ] Phase 2 `mobile/` scaffold created
- [ ] Phase 3 web adapted and deployed, web re-verified
- [ ] Phase 4 Android: debug on device / release `.aab` uploaded
- [ ] Phase 5 iOS: simulator / device / TestFlight
- [ ] Phase 6 listing and review notes
- [ ] Phase 7 device checklist passed
- [ ] Phase 8 docs and agent rules written
