---
name: repo-memory
description: Override Claude Code's auto-memory location to a configurable directory inside the project repo, with a confirmation gate before any write. TRIGGER when about to save or update an auto-memory file based on your trained auto-memory detection (e.g., user states a preference, constraint, project fact, or feedback worth remembering across sessions). Also handles /repo-memory commands for viewing, listing, and auditing existing memories.
---

# repo-memory

Memories live in a project-repo directory (configured per-project as `REPO_MEM_DIR` in `CLAUDE.md`) instead of `~/.claude/projects/.../memory/`. Every write goes through a user confirmation gate.

This skill handles WHERE memories live and HOW writes are gated. It does not specify WHAT memories look like — frontmatter, type names, file naming, and MEMORY.md structure all come from your system prompt's auto-memory section.

## REPO_MEM_DIR

`REPO_MEM_DIR` is the memory directory token. Resolve it by reading `CLAUDE.md`'s `## Memory` section for a line like ``REPO_MEM_DIR: `<path>` `` and extracting the backtick-quoted path. If the section or line is missing, install is incomplete.

## Routing

For `/repo-memory <command>` invocations, jump to "Manual commands" at the bottom. Otherwise this is an auto-triggered save — follow Steps 1-3 in order.

## Step 1 — Install check

Check:
- `CLAUDE.md` has a `## Memory` section with a parseable `REPO_MEM_DIR:` line
- The resolved `REPO_MEM_DIR/MEMORY.md` exists
- `~/.claude/projects/<project-id>/memory/` (default location — find the project-id by listing `~/.claude/projects/`) for any existing memory files
- `~/.claude/settings.json` and `.claude/settings.local.json` for `autoMemoryEnabled`

If install is incomplete, read `references/install.md` and run the install flow before continuing. If `autoMemoryEnabled: false`, briefly warn the user that proactive memory detection won't fire (only manual saves work) and continue.

## Step 2 — Drift check

If `~/.claude/projects/<project-id>/memory/MEMORY.md` is newer than `REPO_MEM_DIR/MEMORY.md`, files were written outside this skill. List them and offer three options: migrate (move into REPO_MEM_DIR), update (show what changed in your auto-memory system prompt so the skill can be fixed), or ignore. After the user picks, resume the save.

## Step 3 — Save flow

Show the proposed write before doing it. For a new memory, show two changes: the topic file (full content as a code block) and the `MEMORY.md` index update (as a diff). For an update to an existing memory, show a diff of the topic file; if the index entry's description also changes, show that diff too. Ask to save. On approval, write. On denial, ask if they want to edit, save with changes, or skip.

## Manual commands

For `/repo-memory <command>`, resolve `REPO_MEM_DIR` first. If install is incomplete, warn briefly but continue — read-only commands work in degraded mode (they just have nothing to show).

- `/repo-memory`, `/repo-memory list`, `/repo-memory show <name>` — read `references/view.md`
- `/repo-memory audit` — read `references/audit.md`

## Principles

- **Format-neutral.** This skill never specifies frontmatter fields, type names, file naming, or MEMORY.md structure. Those come from the system prompt's auto-memory section.
- **Path-configurable.** `REPO_MEM_DIR` is per-project, defined in CLAUDE.md.
- **No marker files.** All state checks use the filesystem (file existence, mtimes, string matches in CLAUDE.md).
- **Lazy install.** First save in a fresh repo prompts install. Read-only commands work in degraded mode.
- **Two-write awareness.** Saving a memory changes the topic file AND the index. Always show both.
