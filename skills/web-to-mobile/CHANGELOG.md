# Changelog

## 0.1.1 — 2026-11-19

Repository workflow rules: mandatory version bump on every change, mandatory local install to `~/.claude/skills` and `~/.codex/skills`,
mandatory commit + push to GitHub. The skill still prints `web-to-mobile v<VERSION>` at start. No functional change to the skill itself.

## 0.1.0 — 2026-11-19

Initial release: Capacitor remote-URL workflow from web app to TestFlight / Google Play. Phases 0–8, seven references,
parameterised templates (Android/iOS scripts, native config, web helpers, `.well-known` files, docs), `scripts/render.sh`,
`scripts/assetlinks-add.sh`, `scripts/selftest.sh`. Derived from a production Capacitor setup; all product specifics removed.
iOS scripts were written without a Mac in the authoring environment and need their first real run on macOS.
