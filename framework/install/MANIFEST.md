# Orca Install Manifest

This file is the authoritative enumeration of every file the Orca install ships into a user project. `INSTALL.md` consults it during install; task 006b's pruning step deletes any file under `.orca/` whose path matches a framework glob in this manifest but whose specific path is not listed here.

Each row is annotated with a classification:

| Classification | Semantics |
|----------------|-----------|
| `framework`  | Overwrite on every install. Source of truth is `framework/` in the Orca repo. Prune if removed from the canonical list. |
| `skill`      | Overwrite on every install. Project-scoped under `.claude/skills/`. |
| `once-only`  | Create if absent. Never overwrite — user edits it. |
| `scaffold`   | Directory + `.gitkeep` if the directory is absent. Never touch contents. |
| `hook`       | Overwrite on every install. `chmod +x` afterward. Git config touched conditionally. |
| `gitignore`  | Entries appended if missing; never removed. |

Sources are paths inside this repo (the Orca source repo). Targets are paths inside the user project being installed into.

---

## Framework files (`framework`)

Overwrite on upgrade. All paths under `.orca/` that match the shapes below but are not listed here are candidates for pruning in 006b.

| Source | Target |
|--------|--------|
| `framework/seed.md` | `.orca/seed.md` |
| `framework/ralph.md` | `.orca/ralph.md` |
| `framework/processes/prd.md` | `.orca/processes/prd.md` |
| `framework/perspectives/architect.md` | `.orca/perspectives/architect.md` |
| `framework/perspectives/code-cleaner.md` | `.orca/perspectives/code-cleaner.md` |
| `framework/perspectives/code-reviewer.md` | `.orca/perspectives/code-reviewer.md` |
| `framework/perspectives/design-reviewer.md` | `.orca/perspectives/design-reviewer.md` |
| `framework/perspectives/drafter.md` | `.orca/perspectives/drafter.md` |
| `framework/perspectives/explorer.md` | `.orca/perspectives/explorer.md` |
| `framework/perspectives/implementer.md` | `.orca/perspectives/implementer.md` |
| `framework/perspectives/planner.md` | `.orca/perspectives/planner.md` |
| `framework/perspectives/qa-engineer.md` | `.orca/perspectives/qa-engineer.md` |
| `framework/perspectives/spec-reviewer.md` | `.orca/perspectives/spec-reviewer.md` |
| `framework/modes/code/MODE.md` | `.orca/modes/code/MODE.md` |
| `framework/templates/prd.json` | `.orca/templates/prd.json` |

### Pruneable patterns

A file under `.orca/` is pruneable (in 006b) if its path matches one of these globs AND the specific path is not in the list above:

- `.orca/perspectives/*.md`
- `.orca/modes/*/MODE.md`
- `.orca/modes/*/**/*.md`
- `.orca/processes/*.md`
- `.orca/templates/*`
- `.orca/seed.md`
- `.orca/ralph.md`

Files under `.orca/` that do not match any of these patterns (e.g., `.orca/.install-state.json`, future user-added subdirectories) are NOT pruneable — they are untouched.

---

## Skills (`skill`)

Project-scoped. Overwrite on every install. Entire tree under each skill directory is mirrored.

| Source | Target |
|--------|--------|
| `.claude/skills/ralph/SKILL.md` | `.claude/skills/ralph/SKILL.md` |
| `.claude/skills/discover/SKILL.md` | `.claude/skills/discover/SKILL.md` |
| `.claude/skills/refine/SKILL.md` | `.claude/skills/refine/SKILL.md` |
| `.claude/skills/repo-memory/SKILL.md` | `.claude/skills/repo-memory/SKILL.md` |
| `.claude/skills/repo-memory/references/audit.md` | `.claude/skills/repo-memory/references/audit.md` |
| `.claude/skills/repo-memory/references/detection.md` | `.claude/skills/repo-memory/references/detection.md` |
| `.claude/skills/repo-memory/references/install.md` | `.claude/skills/repo-memory/references/install.md` |
| `.claude/skills/repo-memory/references/utility.md` | `.claude/skills/repo-memory/references/utility.md` |

---

## Once-only writes (`once-only`)

Create if absent, never overwrite. Users own the contents after the first install.

| Source | Target |
|--------|--------|
| `templates/CLAUDE.md.template` | `CLAUDE.md` |
| `templates/.claudeignore` | `.claudeignore` |

---

## Scaffolds (`scaffold`)

Create the directory and a `.gitkeep` inside if the directory is absent. Do not touch any existing contents.

- `orca-context/overrides/.gitkeep`
- `orca-context/knowledge/.gitkeep`
- `orca-context/prds/.gitkeep`
- `orca-context/designs/.gitkeep`
- `orca-context/tasks/.gitkeep`

---

## Git hooks (`hook`)

Overwrite on every install. `chmod +x` afterward. Then `git config core.hooksPath .git-hooks` only if the current value is empty or already `.git-hooks`; otherwise warn and skip.

| Source | Target |
|--------|--------|
| `templates/.git-hooks/pre-push` | `.git-hooks/pre-push` |

---

## `.gitignore` entries (`gitignore`)

Append missing entries from the canonical list. The current list is empty; the mechanism exists for future entries.

```
# (none today)
```

---

## Files that do NOT ship

Explicitly excluded from the install, for reference:

- `framework/` itself (the user gets `.orca/`, a derived copy)
- `framework/install/MANIFEST.md` (this file — consulted at install time, not copied)
- `INSTALL.md` (the runbook Claude reads — not copied into user projects)
- `docs/`, top-level `CLAUDE.md`, `BACKLOG.json`, `README.md`, `WHY.md`, `progress.txt`, this repo's `orca-context/`
- Docker infrastructure: `Dockerfile`, `orca-start.sh`, `orca-attach.sh`, `orca-clone.sh`, `orca-reset.sh`, `orca-loop.sh`, `orca-once.sh`, `orca-reset.sh`, `ORCA_PROMPT.md`, `node_modules/`
- `framework/template.claude.settings.json` — task 007 moves this into `framework/templates/claude-settings.json` and wires the settings prompt; until then, the settings prompt is a no-op

---

## `.orca/.install-state.json` schema

Written by the install itself (not copied from a template). Contains:

```json
{
  "install_version": "006a",
  "last_installed_at": "2026-04-14T12:00:00Z",
  "settings_prompted_at": null,
  "settings_destination": null
}
```

Fields:

- `install_version` (string): the Orca install version that last touched this project. Task 006a writes `"006a"`; 006b bumps it; each subsequent PRD that changes install behavior bumps it. Used by upgrade logic to know which migrations to run.
- `last_installed_at` (string, ISO 8601 UTC): timestamp of the most recent install run.
- `settings_prompted_at` (string | null, ISO 8601 UTC): set when the settings prompt has been offered. Upgrade reads this; if non-null, the prompt is skipped. Task 007 fills this in; 006a always writes `null`.
- `settings_destination` (string | null): one of `"project"`, `"user"`, `"skipped"`, or `null`. Task 007 fills this in; 006a always writes `null`.

Future fields may be added by later tasks; consumers must tolerate unknown keys.
