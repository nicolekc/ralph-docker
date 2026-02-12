# Project Structure

How the framework files are organized in a project that uses Ralph.

## Two Directories

### `.ralph/` — Framework Files (copied, don't edit)

Installed from the framework repo. Contains roles, processes, the seed, and templates. Treat as read-only. If the framework updates, these files get replaced.

```
.ralph/
  seed.md                  # Working style principles
  ralph.md                 # Orchestrator instructions
  roles/
    architect.md
    code-reviewer.md
    design-reviewer.md
    spec-reviewer.md
  processes/
    build-cycle.md
  templates/
    prd.json               # PRD template
```

### `ralph-context/` — Project-Specific Files (your edits)

No dot — this is human-inspectable. Everything specific to this project. Starts nearly empty with bare templates. Grows as the project does.

```
ralph-context/
  overrides/               # Additions to .ralph/ (mirror the structure)
    roles/                 # e.g., architect.md with project-specific context
  knowledge/               # One file per learning, append-only
  prds/                    # Durable: task definitions (PRD files)
  designs/                 # Durable: design documents, investigations
```

If an override needs to *subtract* from a framework file, that's a signal the framework file is too prescriptive. Fix the framework, don't hack the override.

### `.ralph-tasks/` — Per-Task Workspaces (machinery)

Dot-prefixed — this is machinery, not for casual browsing. Complex tasks accumulate context here.

```
.ralph-tasks/
  <prd-name>/              # Scoped by PRD (task IDs restart per PRD)
    <task-id>/
      progress.txt         # What's been tried, what worked, what didn't
      (any other files)    # Investigation notes, debug dumps, brain dumps, etc.
```

**What goes here:**
- `progress.txt` — structured log of what's been tried (append-only)
- Investigation notes, design thinking, brain dumps
- Debug traces or reproduction steps
- Prior attempt outputs (when a task is redone)
- Any file that helps the next agent understand the task's history

### progress.txt Conventions

One `progress.txt` per task (not per role). Append-only, timestamped entries. Each entry records who did what and the result.

```
## [timestamp] Architect
Approach: [brief summary]
Key decisions: [what and why]

## [timestamp] Implementer
Changes: [files modified]
Tests: [pass/fail summary]
Committed: [hash]

## [timestamp] Reviewer (round 1)
Verdict: [approved / issues found]
Issues: [if any]
```

This creates a single narrative thread for the task. A future agent or human can read it top-to-bottom and understand the full history.

**Ephemeral vs durable:**
- Task workspaces are **durable until the task merges to main**, then disposable
- Debug logs and scratch files within it are **ephemeral** — useful during the task, can be cleaned up before merge
- Design decisions and investigation conclusions should be extracted to `ralph-context/designs/` if they have lasting value

## CLAUDE.md

The project's CLAUDE.md remains the primary project context file. The seed (`.ralph/seed.md`) is a supplement, not a replacement. CLAUDE.md has project-specific commands, conventions, and context that the framework doesn't know about.

## Self-Installation

When the ralph-docker repo installs into itself:
- `framework/` is the **source** (canonical, edited by developers)
- `.ralph/` is the **installed copy** (generated, overwritten on install)
- These are different directories — no conflict

## AGENTS.md Pattern

Projects can use `AGENTS.md` files in subdirectories to provide per-directory context to AI agents. These contain learnings, instructions, and conventions specific to the code in that directory. CLAUDE.md at the top level should instruct agents to read and write AGENTS.md files as they learn about the codebase.

The right balance for AGENTS.md writes is an open question — too liberal creates noise, too conservative loses knowledge. See the knowledge file on this topic if one exists.

## .gitignore Considerations

```
# Task workspace ephemeral files
.ralph-tasks/*/*/debug-*
.ralph-tasks/*/*/scratch-*

# Ralph logs (if using the bash runner)
ralph-logs/
```
