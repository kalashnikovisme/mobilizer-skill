# Phase 0 — Discovery and questionnaire

Goal: learn everything once, record it in `mobile/MOBILE.md` (no secrets), never ask again.
Inspect the repo FIRST (read-only), then ask only what the repo cannot answer. Ask all open questions
in ONE message with answer options; do not interrogate one at a time.

## A. What to find in the target repository (do not ask the user these)

| Question | Where to look |
|---|---|
| Repo rules for agents (MUST be respected, never overridden) | `AGENTS.md`, `CLAUDE.md`, `.agents/`, `.claude/`, `.cursor/`, `.codex/`, `CONTRIBUTING.md`, README, `docs/` |
| Files agents are forbidden to create (e.g. "do not create CLAUDE.md") | same files; grep for `never create`, `do not create`, `forbidden` |
| Web framework and version | `package.json` (next, nuxt, @sveltejs/kit, vite, remix, astro), `Gemfile` (rails), `composer.json`, `pyproject.toml`/`manage.py` (django) |
| Whether host Node is allowed ("never run node/pnpm on the host", docker/dip-only) → decides `MOBILE_NPM`/`MOBILE_CAP` | `AGENTS.md`, `.agents/running-commands.md`, `dip.yml` (existing `mobile-*` commands?) |
| Rendering model: SSR/server vs static export | `next.config.*` (`output: 'export'`?), adapters, presence of API routes/middleware |
| How to run dev/build/lint/test | `Makefile`, `dip.yml`, `docker-compose*.yml`, `.mise.toml`/`.tool-versions`, `package.json` scripts, `bin/*`. If the repo mandates a wrapper (docker/dip/mise), web commands use it — but native builds (Xcode, Android SDK) never run in containers |
| Deploy mechanism and the deploy command/rules | `config/deploy*.yml` (Kamal), `vercel.json`, `fly.toml`, `.github/workflows`, `docs/deploy*` — note any "never deploy X" rules |
| Production URL | README, deploy config (`proxy.host`/`hosts`), `NEXT_PUBLIC_*_URL`, `.env.example`, CI. If not certain → ASK |
| Middleware / edge code and its matcher | `middleware.ts`, `proxy.ts`, `config/routes.rb`, `app.use(...)` |
| Auth methods | search `signIn`, `oauth`, `passport`, `next-auth`/`auth.js`, `devise`, `supabase.auth`, `google`, `apple`, `facebook` |
| Payments / subscriptions / paywall | `stripe`, `paddle`, `lemonsqueezy`, `paypal`, `checkout`, `pricing`, `subscription`, `billing` |
| Analytics / crash / ads SDKs | `posthog`, `sentry`, `gtag`, `fbq`, `mixpanel`, `amplitude`, `adsbygoogle` (needed for privacy answers) |
| Permissions the web app triggers | `getUserMedia`, `MediaRecorder`, `navigator.geolocation`, `Notification.requestPermission`, `<input type=file capture>` |
| Account deletion exists? | grep `delete account`, `deleteUser`, `/delete-account` |
| Secrets store | `.sops.yaml`, `secrets.sops.yaml`, `.env.vault`, 1Password refs (`op://`), `bin/secrets`, `config/credentials` |
| Existing `mobile/`, `ios/`, `android/`, `capacitor.config.*` | if it has content: this is an UPDATE, not a fresh scaffold — read first. An empty `mobile/` directory is a fresh start |
| Who may deploy / touch production | agent rules ("never run production commands", "deploy only via skill X", branch rules) → Phase 3 deploy becomes a human handoff if forbidden |
| Commit conventions | `git log --oneline -20`, CONTRIBUTING, commitlint, lefthook/husky hooks |
| Skill/instruction conventions | existing `.claude/skills/`, `.agents/`, `.codex/`, `AGENTS.md` index style |

Print a short **Findings** table to the user, then the questionnaire for the rest.

## B. Questionnaire (single message, with options)

1. **App name** (home-screen name, ≤ ~12 chars looks best) and **short slug** (`[a-z0-9-]`).
2. **Application / bundle id**, reverse-DNS, e.g. `com.company.product`.
   ⚠ **Immutable after the first store upload** (Google Play and App Store). It also identifies signing,
   App Links and Universal Links. Confirm it explicitly; propose a default from the domain (`acme.com` → `com.acme.app`).
   Use the product owner's domain, not a developer's personal one.
3. **Production URL** (https, final domain — not a preview URL).
4. **Targets**: Android / iOS / both.
5. **Accounts** — Google Play Console (one-time US$25) and Apple Developer Program (US$99/year):
   none yet / have / free Apple ID only. For Apple: **Individual** (quick; seller name = person) vs
   **Organization** (needs D-U-N-S + legal entity; days–weeks). Who owns them — the **product owner/client** or the user?
   (The owner must do the console-only steps; plan for handoff checklists.)
6. **Host OS** of this machine (`uname -s`). iOS builds only on macOS; otherwise Android now, iOS prepared and a
   Mac handoff document produced.
7. **OAuth/social logins** in the web app → decides Sign in with Apple (App Store 4.8) and the external-browser flow;
   the exact OAuth **callback path(s)**.
8. **Payments**: exist? (decides how aggressively the UI must be gated; see store-compliance.md).
9. **Push notifications** wanted now? (FCM/APNs setup is extra work; default: not in v1.)
10. **Languages** of the product (listing text, permission strings, offline page).
11. **Secrets store** the repo uses (SOPS/age, 1Password, files outside the repo, CI secrets) — only if push or other secrets are needed.
12. **Brand**: icon source (≥1024² PNG, no transparency for iOS), splash/brand colour.

Then write `mobile/MOBILE.md` from `templates/MOBILE.md` (keep the `env` block parseable), add a Findings
section if useful, and commit it. Re-read it at the start of every later session instead of asking again.
