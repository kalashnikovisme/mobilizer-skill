# Repository Instructions

Follow all instructions in `AGENTS.md`.

Entry point of the skill: `skills/web-to-mobile/SKILL.md`. In Claude Code, load `references/*.md` explicitly with the Read tool
when the phase in `SKILL.md` says so. Run `skills/web-to-mobile/scripts/selftest.sh` after changing templates or scripts.

## End-of-task routine (mandatory)
Bump `skills/web-to-mobile/VERSION` + CHANGELOG → `selftest.sh` → install to `~/.claude/skills/` and `~/.codex/skills/` → commit → `git push`.
Details in `AGENTS.md` rules 4, 8, 9.
