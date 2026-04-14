# Orca

This repo is the Orca agent framework — composable tools for AI-assisted software development. It is also self-hosting: the framework is installed into itself for development.

Read `.orca/seed.md` before starting any task.

## What This Repo Contains

- `framework/` — **Source** of framework files (perspectives, processes, seed, templates, modes, install manifest). Canonical. **ALL edits to framework files go here.**
- `.orca/` — **Installed copy** of `framework/` (minus `framework/install/`). **NEVER edit `.orca/` directly** — edit in `framework/` and re-run the install to sync.
- `orca-context/` — Project-specific context (overrides, knowledge, PRDs, designs, durable task context)
- `docs/` — Framework design documentation
- `.claude/skills/` — Claude Code skills (`/ralph`, `/discover`, `/refine`, `/repo-memory`)
- `templates/` — Once-only install scaffolds (`CLAUDE.md.template`, `.claudeignore`, `.git-hooks/`)
- Docker / bash infrastructure — `Dockerfile`, `orca-start.sh`, `orca-loop.sh`, `orca-once.sh`, `orca-reset.sh`, `orca-clone.sh`, `orca-attach.sh`, `ORCA_PROMPT.md` (bash-loop entry). None of these ship into installed projects.
- `INSTALL.md` — Agent-executable install runbook (read by Claude Code on `Install this project: <url>`)
- `framework/install/MANIFEST.md` — Canonical file-by-file install inventory
- `BACKLOG.json` — Pre-PRD backlog: future improvements, unsolved problems, and working knowledge from real project use. Check before starting framework evolution work.

## Framework / Installed Boundary

Files that SHIP into target projects (the install copies these):

- `.orca/` core — `seed.md`, `ralph.md`, `perspectives/`, `processes/`, `templates/`, `modes/`
- `.claude/skills/` — `ralph`, `discover`, `refine`, `repo-memory`
- Once-only scaffolds from `templates/` — `CLAUDE.md.template` → `CLAUDE.md`, `.claudeignore`, `.git-hooks/pre-push`
- Empty `orca-context/` scaffold dirs

Files that STAY in this repo (never shipped): `docs/`, top-level `CLAUDE.md`, this repo's `orca-context/`, `BACKLOG.json`, `README.md`, `WHY.md`, Docker / bash scripts, `ORCA_PROMPT.md`, `Dockerfile`, `framework/install/MANIFEST.md`, `INSTALL.md`.

See `framework/install/MANIFEST.md` for the exact per-row classification.

## How to Install / Sync

The install is agent-driven. To sync `framework/` → `.orca/` in this self-hosted repo, in Claude Code say:

```
Install this project: .
```

That runs `INSTALL.md`, detects self-install mode, and does a `framework/` → `.orca/` sync plus stale-file pruning. There is no `install.sh` — the runbook replaced it.

## Essential Reading

1. **`docs/design-principles.md`** — 11 principles governing framework design. Load-bearing ones:
   - **P2 (Principles Over Prescriptions)** — state principles, trust the executor
   - **P3 (Specification-Creativity Tradeoff)** — over-specifying REDUCES quality
   - **P8 (Lightning-Quick Descriptions)** — every file costs tokens, be minimal

2. **`docs/structure.md`** — how framework files are organized in an installed project
3. **`docs/execution-strategies.md`** — subagent vs bash-loop modes

## Framework Design Anti-Patterns

From analysis of OMC, Superpowers, and Gas Town:

- **Prescriptiveness trap**: more rules → more corner cases → more patches → complexity explosion
- **Anti-rationalization tables**: adversarial arms race. Trust and correct after, don't pre-empt
- **Over-classification of roles**: 30 agent types creates a routing problem. Keep roles broad
- **Custom vocabulary**: invented terminology wastes tokens and confuses
- **Mandatory activation**: let the AI decide what applies

## Git Rules

- NEVER push to main directly
- Always work on feature branches (`ralph/<prd-name>`)
- Small, logical commits with clear messages

## How to Run /ralph

```
/ralph orca-context/prds/001-foundation.json
```

Ralph reads the PRD, dispatches subagents to work through task pipelines, and pushes when done. Each pipeline step is a subagent with clean context.

## Modes

PRDs may declare a `mode` field. Modes are pluggable domain add-ons at `framework/modes/<name>/MODE.md` — a single file that supplies domain-specific PRD process content and names the perspectives it uses. `code` is the canonical mode. A PRD with no `mode` runs on base perspectives only. Adding a mode is a single-file change.

## Key Knowledge Files

Knowledge files live in `orca-context/knowledge/` (one file per learning, append-only). Currently empty — learnings from earlier PRDs are in their respective `orca-context/tasks/` directories.
