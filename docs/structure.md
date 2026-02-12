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

### `local/` — Project-Specific Files (your edits)

Everything specific to this project. Starts nearly empty with bare templates. Grows as the project does.

```
local/
  overrides/               # Additions to .ralph/ (mirror the structure)
    roles/                 # e.g., architect.md with project-specific context
  knowledge/               # One file per learning, append-only
```

If an override needs to *subtract* from a framework file, that's a signal the framework file is too prescriptive. Fix the framework, don't hack the override.

### Project Root — Work Artifacts

These live wherever is natural for the project:

```
prds/                      # Durable: task definitions (PRD files)
designs/                   # Durable: design documents
tasks/                     # Per-task workspaces
  <task-id>/
    progress.txt           # What's been tried, what worked, what didn't
    (any other files)      # Investigation notes, debug dumps, etc.
```

## Per-Task Workspaces

Complex tasks accumulate context in `tasks/<task-id>/`. This directory is the task's working memory.

**What goes here:**
- `progress.txt` — structured log of what's been tried (append-only)
- Investigation notes
- Debug traces or reproduction steps
- Prior attempt outputs (when a task is redone)
- Any file that helps the next agent understand the task's history

**Ephemeral vs durable:**
- The task workspace is **durable until the task merges to main**, then disposable
- Debug logs and scratch files within it are **ephemeral** — useful during the task, can be cleaned up before merge
- Design decisions and investigation conclusions should be extracted to `designs/` if they have lasting value

## CLAUDE.md

The project's CLAUDE.md remains the primary project context file. The seed (`.ralph/seed.md`) is a supplement, not a replacement. CLAUDE.md has project-specific commands, conventions, and context that the framework doesn't know about.

## .gitignore Considerations

```
# Ephemeral task state (optional — some teams keep it, some don't)
tasks/*/debug-*
tasks/*/scratch-*

# Ralph logs (if using the bash runner)
ralph-logs/
```
