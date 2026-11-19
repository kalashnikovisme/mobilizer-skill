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
4. **Versioning (mandatory, every time).** Any change to the repository's content bumps `skills/web-to-mobile/VERSION` (semver) exactly once, in the
   same task, BEFORE install/validation/commit, and adds a `skills/web-to-mobile/CHANGELOG.md` entry. PATCH wording/fixes, MINOR new workflows/scripts,
   MAJOR breaking behaviour changes. Never leave VERSION unchanged after modifying the skill. `SKILL.md` makes the agent print
   `web-to-mobile v<VERSION>` first whenever the skill starts, so the number must always match the installed content.
5. Update `README.md` when user-visible behaviour of the skill changes.
6. Do not add `.claude-plugin/plugin.json` (conflicts with `marketplace.json`).
7. Native scripts that could not be executed in the authoring environment (iOS scripts without a Mac) must say so in the changelog
   until someone has run them on real hardware; after a real run, record it here and fix the scripts.
8. **Local install (mandatory, every time).** After every local change to the skill (and after the version bump), install the current working tree on this
   computer, replacing the old copy, so the next session uses it:
   ```bash
   skills/web-to-mobile/scripts/selftest.sh
   claude plugin validate . --strict
   rm -rf ~/.claude/skills/web-to-mobile && cp -R ./skills/web-to-mobile ~/.claude/skills/web-to-mobile
   rm -rf ~/.codex/skills/web-to-mobile  && cp -R ./skills/web-to-mobile ~/.codex/skills/web-to-mobile
   diff -r ./skills/web-to-mobile ~/.claude/skills/web-to-mobile && echo "installed v$(cat skills/web-to-mobile/VERSION)"
   ```
   Report the installed version. This is for local use; the recommended install for other people is the plugin marketplace in `README.md`.
9. **Commit and push (standing authorization, mandatory).** Every task that changes this repository ends with: version bump → selftest → local install →
   `git commit` → `git push` to `origin` on GitHub. Do not wait for a separate request and do not leave changes uncommitted or unpushed.
   Commit each logical change separately; never rewrite history or force-push. If the push fails, report the real error.
