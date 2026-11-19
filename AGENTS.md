# Repository Instructions

This repository contains one agent skill: **`web-to-mobile`** (`skills/web-to-mobile/`). It guides an AI agent from
"we have a working web app" to "the app is on the phone, signed, and in TestFlight / Google Play".
Start with `skills/web-to-mobile/SKILL.md` (works in Claude Code, Codex, Cursor and any agent that can read files).

## Skill index
- `skills/web-to-mobile/SKILL.md` — process (Phases 0–8), principles, template map
- `skills/web-to-mobile/references/` — discovery, web-adaptation, android, ios, store-compliance, secrets-and-signing, test-checklist
- `skills/web-to-mobile/templates/` — parameterised scripts/configs rendered into the TARGET repo by `scripts/render.sh`
- `skills/web-to-mobile/scripts/` — `render.sh`, `assetlinks-add.sh`, `selftest.sh`

## Cross-platform requirement
Everything must stay readable and actionable for Claude Code, Codex and other agents: use platform-neutral wording, label
platform-specific instructions (**Claude Code** / **Codex**), keep explicit relative-path guidance in `SKILL.md`
(Claude Code does not auto-load `references/*`; it must Read them).

## Rules for changing this repository
1. **No product-specific content** in the skill (names, domains, Firebase projects, command wrappers). Everything is parameterised
   from the target repo's `mobile/MOBILE.md`. `scripts/selftest.sh` greps for leftovers of the project the templates came from.
2. After ANY change to `templates/` or `scripts/`, run `skills/web-to-mobile/scripts/selftest.sh` and fix failures
   (renders all templates, `bash -n`, shellcheck when installed, XML/JSON/Ruby checks, placeholder and leakage guards).
3. Keep `SKILL.md` ≲ 250 lines; details go to `references/`.
4. Versioning: bump `skills/web-to-mobile/VERSION` (semver) exactly once per repository-changing task and add a `CHANGELOG.md` entry.
   PATCH wording/fixes, MINOR new workflows/scripts, MAJOR breaking behaviour changes.
5. Update `README.md` when user-visible behaviour of the skill changes.
6. Do not add `.claude-plugin/plugin.json` (conflicts with `marketplace.json`).
7. Native scripts that could not be executed in the authoring environment (iOS scripts without a Mac) must say so in the changelog
   until someone has run them on real hardware; after a real run, record it here and fix the scripts.
8. Local dev sync (developer-only): `claude plugin validate . --strict`, then copy `skills/web-to-mobile` to
   `~/.claude/skills/web-to-mobile` and `~/.codex/skills/web-to-mobile`.
9. Commit each logical change separately; do not rewrite history.
