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
| `framework/templates/claude-settings.json` | `.orca/templates/claude-settings.json` |

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

> 006b implementer: when you add new framework files to this manifest, check that a pruneable glob above covers each one. Current coverage exactly matches the framework files list; any new top-level `.orca/*.md` file (beyond seed/ralph) would need either an explicit glob entry or a top-level `.orca/*.md` glob — resist broadening it until a real need appears, so we don't prune user files by accident.

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
- `docs/`, top-level `CLAUDE.md`, `BACKLOG.json`, `README.md`, `WHY.md`, this repo's `orca-context/`, this repo's `prds/` (the /refine skill reads `prds/PRD_REFINE.md` only when run from the source repo)
- Docker infrastructure: `Dockerfile`, `orca-*.sh` (`start`, `attach`, `clone`, `reset`, `loop`, `once`), `ORCA_PROMPT.md`, `node_modules/`

---

## `.orca/.install-state.json` schema

The sentinel's schema is documented in `INSTALL.md` under "`.orca/.install-state.json` schema". That's the canonical source — don't duplicate it here.
