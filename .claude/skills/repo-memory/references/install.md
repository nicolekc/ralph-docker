# Install flow

Idempotent — propose each item only if it's not already done.

The goal: set up `REPO_MEM_DIR/MEMORY.md` (default `REPO_MEM_DIR: .memory`).

First, check the built-in location (`~/.claude/projects/<project-id>/memory/`) for any existing memory files. If any are present, they are candidates for migration into `REPO_MEM_DIR`.

Propose to the user, for whichever of these aren't done:

- **Directory** — create the directory specified by `REPO_MEM_DIR`
- **CLAUDE.md `## Memory` section + `REPO_MEM_DIR/MEMORY.md` index** — one item; these can't exist without each other. Add a `## Memory` section to `CLAUDE.md` that defines `REPO_MEM_DIR` and points to the index, and create `REPO_MEM_DIR/MEMORY.md` (empty, or populated with migrated content if any was found above). Explain why: future agents read the index on startup to know what memories exist and where to write new ones
- **Existing memories from the built-in location** — if any were found, recommend migrating so they're versioned with the project. Explain the tradeoff if they don't: orphaned in `~/.claude/`, invisible to the repo
- **If `autoMemoryEnabled: false`** — Claude Code's auto-memory is off, so detection instructions aren't injected into the system prompt. Offer to add detection guidance inline in the `## Memory` section, drawing the categories and memory format from `references/detection.md`. That way this skill still fires without the built-in feature enabled.

Take the actions the user confirms.

## Migration procedure (when you have files to migrate)

1. Copy each file to `REPO_MEM_DIR`
2. Verify the copies match the originals (byte-compare)
3. Ask for explicit user confirmation before deleting the originals, giving a specific reason (e.g., "originals have been copied successfully; deleting them removes the stale duplicates from the built-in location")
4. Delete the originals on approval
