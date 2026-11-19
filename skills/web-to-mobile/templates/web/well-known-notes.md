# Serving `/.well-known/*` (both files are web changes -> Phase 3 safety rules apply)

Place the rendered files at the web app's static root so they are served at
`{{PROD_URL}}/.well-known/assetlinks.json` and
`{{PROD_URL}}/.well-known/apple-app-site-association`:

| Framework | Put them in |
|---|---|
| Next.js / Vite / CRA / Nuxt 3 / SvelteKit | `public/.well-known/` (SvelteKit: `static/.well-known/`) |
| Rails | `public/.well-known/` |
| Django / Laravel / other | whatever directory the web server serves verbatim |

Requirements (verify with `curl -sI` AFTER deploying the web app):

1. HTTP **200**, no redirects (no http->https hop that Apple/Google do not follow for these files,
   no locale redirect, no auth wall, no trailing-slash redirect).
2. `Content-Type: application/json` for both. `apple-app-site-association` has **no file extension**, so many
   servers send `application/octet-stream` -- add an explicit header rule:
   - Next.js `next.config.*` `headers()`: source `/.well-known/apple-app-site-association`, header `Content-Type: application/json`.
   - nginx: `location = /.well-known/apple-app-site-association { default_type application/json; }`
   - Rails/Rack/Express static: set the header in the static-file options.
3. **Exclude `/.well-known/*` from middleware** (auth, locale redirect, i18n rewrite, bot protection, basic-auth
   on staging). For Next.js, add `.well-known` to the negative-lookahead of `config.matcher`.
4. Do not cache aggressively on the CDN for the first deploy (Apple fetches via its own CDN and caches for days).
5. AASA `components` must exclude API, OAuth-provider, payment and webhook paths, so those links stay in the browser.
6. These files do nothing until the web app is **deployed**; Android verification can take minutes,
   Apple's CDN up to ~24-48 hours after the first change.
