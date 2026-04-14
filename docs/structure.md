# Project Structure

How the framework files are organized in a project that uses Orca.

## Two Directories

### `.orca/` — Framework Files (copied, don't edit)

Installed by `INSTALL.md`. Contains perspectives, processes, the seed, templates, and pluggable modes. Treat as read-only. On upgrade, stale files are pruned and managed files are refreshed per `framework/install/MANIFEST.md`.

```
.orca/
  seed.md                  # Working style principles
  ralph.md                 # Orchestrator instructions
  .install-state.json      # Install sentinel (see INSTALL.md schema)
  perspectives/
    architect.md
    code-cleaner.md
    code-reviewer.md
    design-reviewer.md
    drafter.md
    explorer.md
    implementer.md
    planner.md
    qa-engineer.md
    spec-reviewer.md
  processes/
    prd.md                 # Pipeline model and task lifecycle
    prd-refine.md          # Refinement criteria (read by /refine skill)
  modes/
    code/
      MODE.md              # Code-mode PRD process + perspective registry
  templates/
    prd.json               # PRD template
    claude-settings.json   # Recommended Claude Code settings (offered at install)
```

### `orca-context/` — Project-Specific Files (your edits)

No dot — this is human-inspectable. Everything specific to this project. Starts nearly empty with bare scaffold directories. Grows as the project does.

```
orca-context/
  overrides/               # Additions to .orca/ (mirror the structure)
    perspectives/          # e.g., architect.md with project-specific context
  knowledge/               # One file per learning, append-only
  prds/                    # Durable: task definitions (PRD files)
  designs/                 # Durable: design documents, investigations
  tasks/                   # Durable per-task context (research, brain dumps, design notes)
    <prd-name>/
      <task-id>/
```

If an override needs to *subtract* from a framework file, that's a signal the framework file is too prescriptive. Fix the framework, don't hack the override.

### `orca-context/tasks/` — Durable Task Context

Task-specific context that humans prepare for agents or that emerges during design sessions. Research notes, brain dumps, design challenges, background material. Lives in `orca-context/` because it's human-inspectable and survives beyond task execution.

```
orca-context/tasks/
  <prd-name>/
    <task-id>/
      (research notes, design docs, brain dumps, etc.)
```

**What goes here:**
- Research or investigation notes prepared before task execution
- Design challenge documents with open questions
- Background material that gives the task implementer context beyond the PRD description
- Brain dumps from design sessions

## Modes

Modes are pluggable domain add-ons. Each mode is a single file at `.orca/modes/<name>/MODE.md` (source: `framework/modes/<name>/MODE.md`). A mode file lists the perspectives it uses and supplies mode-specific PRD process content.

A PRD may declare `"mode": "<name>"`; the orchestrator then loads the matching MODE.md. A PRD with no `mode` runs on base perspectives only. Creating a new mode is a single-file change — no framework code touched.

## CLAUDE.md

The project's `CLAUDE.md` remains the primary project context file. The seed (`.orca/seed.md`) is a supplement, not a replacement. `CLAUDE.md` carries project-specific commands, conventions, and invariants the framework doesn't know about.

`CLAUDE.md` is a once-only install write — created from `templates/CLAUDE.md.template` on first install, never overwritten. Populate it with `/discover`.

## Self-Installation

When the Orca source repo installs into itself:

- `framework/` is the **source** (canonical, edited by developers)
- `.orca/` is the **installed copy** (generated, refreshed on install)
- Self-install mode is detected automatically by `INSTALL.md` when both `framework/seed.md` and `framework/ralph.md` are present. It skips remote clone, skips the settings prompt, and does a local sync + prune.

## AGENTS.md Pattern

Projects can use `AGENTS.md` files in subdirectories to provide per-directory context to AI agents. These contain learnings, instructions, and conventions specific to the code in that directory. `CLAUDE.md` at the top level should instruct agents to read and write `AGENTS.md` files as they learn about the codebase.

The right balance for `AGENTS.md` writes is an open question — too liberal creates noise, too conservative loses knowledge. See the knowledge file on this topic if one exists.
