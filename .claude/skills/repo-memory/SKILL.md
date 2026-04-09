---
name: repo-memory
description: Redirect Claude Code's memories to a project-local directory, with user confirmation before any write. TRIGGER when about to save or update an auto-memory file based on your trained auto-memory detection — e.g., the user states their role or preferences, corrects or confirms a non-obvious approach, mentions project goals/bugs/deadlines/stakeholders, or references external systems (trackers, dashboards) — or if asked to record a memory. Also handles /repo-memory commands for listing and auditing memories.
---

# repo-memory

This skill redirects memories from the built-in location (usually `~/.claude/projects/.../memory/`) to project files. The new location is specified as `REPO_MEM_DIR` in project-level instructions such as `CLAUDE.md` (default: `.memory`).

Instead of using the built-in location, read and save all memories from `REPO_MEM_DIR`.

When you detect a memory to write, always ask the user to confirm unless user overrides tell you otherwise. Same for deletes — always confirm, and give a specific reason for why the delete is proposed.

If your system prompt doesn't include an auto-memory section, read `references/detection.md` — it's a fallback spec covering both the detection categories and the memory format.

## Routing

- Auto-triggered save → follow Steps 1-2 below
- `/repo-memory` and subcommands → read `references/utility.md`
- `/repo-memory audit` → read `references/audit.md`

## Step 1 — Install and drift check

Check:
- `CLAUDE.md` has a `## Memory` section with a parseable ``REPO_MEM_DIR: `<path>` `` line
- The resolved `REPO_MEM_DIR/MEMORY.md` exists
- `~/.claude/projects/<project-id>/memory/` (the built-in location — find the project-id by listing `~/.claude/projects/`) for any files
- `~/.claude/settings.json` and `.claude/settings.local.json` for `autoMemoryEnabled`

If anything needs attention — install incomplete, files in the built-in location, or `autoMemoryEnabled: false` — read `references/install.md` and run the install flow. It's idempotent and only proposes what's actually missing.

If files appear in the built-in location *after* install was already done, that's drift: something wrote there bypassing the skill. Check whether your auto-memory system prompt has changed — a change to the system prompt is the most likely cause, and if so the skill's redirect may no longer match it. Call this out explicitly when proposing migration.

## Step 2 — Save flow

Show the proposed write before doing it. For a new memory, show the topic file as a code block and the `MEMORY.md` index update as a diff. For an update, show a diff of the topic file, plus any change to the index entry.

Ask to save. On approval, write both. On denial, ask if they want to edit, save with changes, or skip.

## Principles

- **Format-neutral.** This skill handles WHERE memories live and HOW writes are gated, not WHAT memories look like. Frontmatter fields, type names, and file naming come from the auto-memory system prompt.
- **Path-configurable.** `REPO_MEM_DIR` is defined per-project in CLAUDE.md.
- **Two-write awareness.** Saving a memory changes the topic file AND the index. Always show both.
- **Confirm deletes.** Any delete operation (migration cleanup, audit cleanup) must be confirmed by the user with a specific reason for why the delete is proposed.
