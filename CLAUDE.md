# Ralph Framework

This repo is the Ralph agent framework — composable tools for AI-assisted software development. It is also self-hosting: the framework is installed into itself for development.

## Ralph Framework

Read `.ralph/seed.md` before starting any task.

## What This Repo Contains

- `framework/` — **Source** of framework files (perspectives, processes, seed, templates). This is the canonical version. **ALL edits to framework files go here.**
- `.ralph/` — **Installed copy** of `framework/`. **NEVER edit .ralph/ directly** — edit in `framework/` and sync.
- `ralph-context/` — Project-specific context (overrides, knowledge, designs, PRDs, durable task context)
- `.ralph-tasks/` — Ephemeral per-task agent workspaces (disposable after merge)
- `docs/` — Framework design documentation
- `.claude/skills/` — Claude Code skills (`/ralph`, `/discover`, `/refine`)
- Docker/bash infrastructure — `Dockerfile`, `ralph-start.sh`, `ralph-loop.sh`, etc.

## Framework / Installed Boundary

**Installed into target projects** (via `.ralph/`): `seed.md`, `perspectives/`, `ralph.md`, `processes/`, `templates/`

**Stays in ralph-docker only**: `docs/`, `CLAUDE.md`, `ralph-context/`, Docker/bash scripts

## Essential Reading

1. **`docs/design-principles.md`** — 11 principles governing all framework design. Key ones:
   - **P2 (Principles Over Prescriptions)** — State principles, trust the executor
   - **P3 (Specification-Creativity Tradeoff)** — Over-specifying REDUCES quality
   - **P8 (Lightning-Quick Descriptions)** — Every file costs tokens. Be minimal.

2. **`docs/structure.md`** — How framework files are organized
3. **`docs/execution-strategies.md`** — Subagent and bash loop modes

## Framework Design Anti-Patterns

From analysis of OMC, Superpowers, and Gas Town:

- **Prescriptiveness trap**: More rules → more corner cases → more patches → complexity explosion
- **Anti-rationalization tables**: Adversarial arms race. Trust and correct after, don't pre-empt.
- **Over-classification of roles**: 30 agent types creates a routing problem. Keep roles broad.
- **Custom vocabulary**: Invented terminology wastes tokens and confuses.
- **Mandatory activation**: Let the AI decide what applies.

## Git Rules

- NEVER push to main directly
- Always work on feature branches
- Small, logical commits with clear messages

## How to Run /ralph

```
/ralph ralph-context/prds/001-foundation.json
```

Ralph reads the PRD, dispatches subagents to work through task pipelines, and pushes when done.

## Key Knowledge Files

Knowledge files live in `ralph-context/knowledge/` (one file per learning, append-only). Currently empty — learnings from earlier PRDs are in their respective `ralph-context/tasks/` directories.
