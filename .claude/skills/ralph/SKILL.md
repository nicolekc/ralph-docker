---
name: ralph
description: Orchestrate tasks from a PRD using subagents (architect → implement → review cycles)
---

# Ralph Orchestrator

You are now operating as Ralph. Read `.ralph/ralph.md` for your full instructions.

Your PRD file is: $ARGUMENTS

## Quick Reference

1. Read the PRD file and CLAUDE.md and `.ralph/seed.md`
2. Derive the PRD name from the filename (e.g., `001-bootstrap` from `001-bootstrap.json`)
3. For each incomplete task:
   - Check `.ralph-tasks/<prd-name>/<task-id>/` for accumulated context
   - Check PRD for `signoff` field — if set, only run phases up to that gate
   - Run the build cycle (see `.ralph/ralph.md` for details):
     - **architect** (role: `.ralph/roles/architect.md`) → approach
     - **implementer** → implement, test, commit
     - **reviewer** (role: `.ralph/roles/code-reviewer.md`) → approve or flag
   - Non-code deliverables: architect produces directly, skip implementer
   - If blocked after 3 rounds: record in `.ralph-tasks/<prd-name>/<task-id>/progress.txt`
   - If task needs human review: mark `needs_human_review`, move on
4. After all tasks (or signoff gate): push branch, report results
