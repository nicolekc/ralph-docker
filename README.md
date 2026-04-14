# Orca

Orca is a framework of composable tools for AI-assisted software development. It ships an orchestrator pattern ("Ralph"), a set of reusable perspectives (planner, architect, implementer, code-cleaner, etc.), pluggable domain modes, and a durable per-task context model — so an agent supervising a PRD can dispatch clean-context subagents through a task pipeline, persist what each one learns, and push real work.

See [WHY.md](WHY.md) for the motivation.

## Install

Open this repo's URL in Claude Code and say:

```
Install this project: <this-repo-url>
```

Claude reads [`INSTALL.md`](INSTALL.md) and executes the install — no shell commands. The runbook covers fresh installs, upgrades, migration from the pre-rename `ralph-*` layout, and a no-op self-install for this repo itself. See `INSTALL.md` for the full state machine and `framework/install/MANIFEST.md` for the canonical file inventory.

A fresh install lays down:

- `.orca/` — framework files (perspectives, processes, seed, templates, modes)
- `.claude/skills/` — `/ralph`, `/discover`, `/refine`, `/repo-memory`
- `orca-context/` — scaffold for project-specific context
- `CLAUDE.md` — project context (populate with `/discover`)
- `.claudeignore`, `.git-hooks/pre-push` — once-only scaffolds

## Usage

### Discover your project

In Claude Code, inside your project:

```
/discover
```

`/discover` explores the repo and populates `CLAUDE.md` with tech stack, conventions, and test setup.

### Write a PRD

A PRD is a JSON file with tasks. Each task has a description, outcome, verification, dependencies, and a pipeline of perspectives.

```json
{
  "name": "User Authentication",
  "description": "Email+password login.",
  "mode": "code",
  "signoff": "full",
  "tasks": [
    {
      "id": "001",
      "description": "What needs to happen and why",
      "outcome": "What done looks like",
      "verification": "How to prove it works",
      "dependencies": [],
      "status": "pending",
      "pipeline": []
    }
  ]
}
```

Save PRDs under `orca-context/prds/`. Template: `.orca/templates/prd.json`.

Refine a PRD before running it:

```
/refine orca-context/prds/001-auth.json
```

### Run Ralph

```
/ralph orca-context/prds/001-auth.json
```

Ralph reads the PRD, plans each task into a pipeline (`planner` → domain perspectives → cleanup), dispatches one subagent per pipeline step, and pushes when done. Each subagent runs with clean context and accumulates durable notes under `orca-context/tasks/<prd-name>/<task-id>/`.

### Modes

Each PRD may declare a `mode` field. Modes are pluggable domain add-ons living in `framework/modes/<name>/MODE.md`. A mode file lists which perspectives it uses and supplies any domain-specific PRD process (e.g. `code` mode's Green Builds, TDD verification, atomic commits, pipeline patterns). A PRD with no `mode` runs on base perspectives only.

Adding a mode is a single-file change: create `framework/modes/<name>/MODE.md`. See `framework/modes/code/MODE.md` as the canonical example.

### Multiple sessions

You can run two or more Ralph sessions against the same project in parallel — e.g. one PRD per session. Each session needs its own working tree and container so they don't collide on git or hijack each other's terminal.

**Bind-mount mode (`orca-start.sh`):** create a git worktree, then point the launcher at it.

```bash
# Terminal A — primary working tree
./orca-start.sh ~/code/myproj              # container: orca-myproj

# Terminal B — second session on a worktree
cd ~/code/myproj
git worktree add ../myproj-prdb ralph/prd-b
./orca-start.sh ~/code/myproj-prdb         # container: orca-myproj-prdb
```

The container name is derived from the folder basename, so two different worktrees produce two different containers automatically.

**Volume mode (`orca-clone.sh`):** use `--session` to get a separate clone.

```bash
./orca-clone.sh https://github.com/me/proj.git                 # container: orca-proj
./orca-clone.sh https://github.com/me/proj.git --session prdb  # container: orca-proj-prdb
```

**Extra terminal on an existing session:** `orca-attach.sh` runs `docker exec -it`. This doesn't start a new Ralph session — it's another shell on the same container, handy for tailing logs. Re-invoking `orca-start.sh` / `orca-clone.sh` against a running session also opens a new shell via `docker exec` instead of hijacking the original TTY.

## Migrating from `ralph-docker`

If you used this framework when it was called `ralph-docker`, run the install again against your project — the runbook's Migrate branch detects `.ralph/` / `ralph-context/`, does the `git mv` + path rewrite + stale-file cleanup in a single commit, and falls through into a normal upgrade.

Leftover Docker artifacts are orphaned but harmless. Clean up when you're done with the last pre-rename session:

```bash
docker rm -f $(docker ps -aq --filter name=ralph-)       # containers
docker volume rm $(docker volume ls -q --filter name=ralph-vol-)  # volumes
docker rmi ralph-claude                                   # image
docker build -t orca-claude:latest .                     # rebuild under new tag
```

## Execution modes

- **Subagent mode** (primary) — interactive Claude Code. `/ralph <prd-path>` dispatches subagents.
- **Bash loop mode** (Docker) — headless. Run `./orca-loop.sh orca-context/prds/<prd>.json 20` inside the container. Each iteration reads `ORCA_PROMPT.md` (a thin wrapper around `.orca/ralph.md`) and completes one pipeline step. Bash-loop files are not shipped into installed projects; they live in this repo for self-hosted use.

See [docs/execution-strategies.md](docs/execution-strategies.md) for a comparison.

## Repository structure

This repo is **self-hosting** — the framework is installed into itself.

| Path | Purpose |
|------|---------|
| `framework/` | **Source** of framework files. All edits go here. |
| `.orca/` | **Installed copy** of `framework/`. Never edit directly. |
| `orca-context/` | Project-specific context (PRDs, designs, durable task context, knowledge, overrides) |
| `docs/` | Framework design documentation |
| `.claude/skills/` | Claude Code skills (`/ralph`, `/discover`, `/refine`, `/repo-memory`) |
| `templates/` | Once-only install scaffolds (`CLAUDE.md.template`, `.claudeignore`, `.git-hooks/`) |
| `INSTALL.md` | Agent-executable install runbook |
| `framework/install/MANIFEST.md` | Canonical file-by-file install inventory |
| `BACKLOG.json` | Pre-PRD backlog: improvements, unsolved problems, working knowledge |

Key framework files:

| File | Purpose |
|------|---------|
| `.orca/seed.md` | Working style principles — agents read before any task |
| `.orca/ralph.md` | Orchestrator instructions |
| `.orca/processes/prd.md` | Pipeline model, task lifecycle |
| `.orca/modes/<mode>/MODE.md` | Mode-specific PRD process + perspective registry |
| `.orca/perspectives/*.md` | Individual role prompts |
| `.orca/templates/prd.json` | PRD template |
| `ORCA_PROMPT.md` | Bash-loop entry point (wraps `.orca/ralph.md`) |

## Design principles

The framework is governed by [11 design principles](docs/design-principles.md). The load-bearing ones:

- **P1 Composable, Not Monolithic** — each piece is useful alone.
- **P2 Principles Over Prescriptions** — state principles, trust the executor.
- **P3 Specification–Creativity Tradeoff** — over-specifying REDUCES quality.
- **P8 Lightning-Quick Descriptions** — every file costs tokens; stay minimal.

## Git workflow

- One branch per PRD: `ralph/<prd-name>`
- One PR per PRD, opened after the first pipeline step completes
- The PR evolves with each push — it's a living dashboard
- Never push to main directly
