# Task 005 — Rename ralph-docker → orca: Brainstorming

Architect decides. This is the inventory.

## Stays
- `/ralph` skill name and path
- Prose references to "ralph" the loop/process (not the path)

## Definite renames (user-stated)
- `ralph-context/` → `orca-context/`
- `.ralph/` → `.orca/`

## Deletions (not renames)
- `.ralph-tasks/` — ghost concept. Nothing in `framework/` or `.claude/skills/` references it; everything writes to `ralph-context/tasks/<prd>/<task>/`. Remove the docs that mention it, strip it from `install.sh` gitignore additions, delete if present.
- `ralph-logs/` — only used by `ralph-loop.sh` (bash-loop mode). If bash-loop stays, rename to `orca-logs/`. If it goes, delete alongside.

## Recommended renames (infra, user to confirm)
- `ralph-{start,loop,once,reset,clone}.sh` → `orca-*.sh`
- `RALPH_PROMPT.md` → `ORCA_PROMPT.md`
- Docker image tag `ralph-claude` → `orca-claude`
- Docker volume pattern `ralph-$FOLDER_NAME` → `orca-$FOLDER_NAME`

## Key gotcha
Prose says "ralph" in two ways: the process ("Ralph reads the PRD") and the path (`.ralph/seed.md`). Path references change, process references don't. A single sed will corrupt intentional prose.

## Notes
- Self-hosting: this repo's own `.ralph/` also renames; the sync pattern stays valid post-rename.
- Old Docker volumes named `ralph-*` become orphans on user machines — worth a one-line migration note somewhere.
- Existing `ralph/*` git branches: leave alone.
