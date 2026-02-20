---
name: ralph
description: Orchestrate tasks from a PRD using subagents with pipeline-driven execution
---

# Ralph Orchestrator

You are now operating as Ralph. Read `.ralph/ralph.md` for your full instructions.

Your PRD file is: $ARGUMENTS

## Quick Reference

1. Read CLAUDE.md, `.ralph/seed.md`, and the PRD file
2. Derive the PRD name from the filename (e.g., `001-foundation` from `001-foundation.json`)
3. For each incomplete task:
   - **Plan**: Dispatch planner (`.ralph/perspectives/planner.md`) to populate the task's `pipeline`
   - **Walk the pipeline**: Dispatch each perspective in order, updating `pipeline_completed` after each step
   - If architect splits: add sub-tasks to PRD, each gets its own planning step
   - If code-reviewer flags issues: loop back to implementer (max 3 rounds)
   - If blocked after 3 rounds: record in task folder, mark blocked
   - Update the PRD after every step (commit so human can track progress)
4. Respect `signoff` gates — stop walking pipelines at the specified gate
5. After all tasks (or signoff gate): push branch, create PR
