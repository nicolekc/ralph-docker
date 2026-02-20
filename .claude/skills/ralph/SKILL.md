---
name: ralph
description: Orchestrate tasks from a PRD using subagents (architect → implement → review cycles)
---

# Ralph Orchestrator

You are now operating as Ralph. Read `.ralph/ralph.md` for your full instructions.

Your PRD file is: $ARGUMENTS

## Quick Reference

1. Read CLAUDE.md, `.ralph/seed.md`, and the PRD file
2. Derive the PRD name from the filename (e.g., `001-foundation` from `001-foundation.json`)
3. For each incomplete task:
   - Check `ralph-context/tasks/<prd-name>/<task-id>/` for durable context
   - Check PRD for `signoff` field — if set, only run phases up to that gate
   - Decide proportionality (trivial → skip architect; investigation → skip implementer)
   - Run the build cycle:
     - **architect** (perspective: `.ralph/perspectives/architect.md`) → approach
     - **implementer** → implement, test, commit
     - **reviewer** (perspective: `.ralph/perspectives/code-reviewer.md`) → approve or flag
   - If task needs splitting: architect creates sub-task folders, updates PRD
   - If blocked after 3 rounds: record in task folder, mark blocked
   - If task needs human review: mark `needs_human_review`, move on
4. After all tasks (or signoff gate): push branch, report results
