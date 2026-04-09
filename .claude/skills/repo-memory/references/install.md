# Install flow

Idempotent — propose each item only if it's not already done.

The goal: set up `REPO_MEM_DIR/MEMORY.md` (default `REPO_MEM_DIR: .memory`).

First, check the built-in location (`~/.claude/projects/<project-id>/memory/`) for any existing memory files. If any are present, they are candidates for migration into `REPO_MEM_DIR`.

Propose to the user, for whichever of these aren't done:

- **Directory** — create the directory specified by `REPO_MEM_DIR`
- **CLAUDE.md `## Memory` section** — add a `## Memory` section to `CLAUDE.md` that defines `REPO_MEM_DIR` and points to the index. Future agents read this on startup to know where memories live.
- **`REPO_MEM_DIR/MEMORY.md` index (+ memory files)** — these go hand-in-hand:
  - If memories were found in the built-in location: create `MEMORY.md` with an index entry per migrated memory, plus the individual memory files themselves (list them by name before proposing migration, with the tradeoff: leave them orphaned in `~/.claude/` and invisible to the repo, or move them in).
  - Otherwise: create an empty `MEMORY.md`.
- **If `autoMemoryEnabled: false`** — Claude Code's auto-memory is off, so detection instructions aren't injected into the system prompt. Offer to add detection guidance inline in the `## Memory` section, drawing the categories and memory format from `references/detection.md`. That way this skill still fires without the built-in feature enabled.

Take the actions the user confirms.

## Migration procedure (when you have files to migrate)

1. Copy each file to `REPO_MEM_DIR`
2. Verify the copies match the originals (byte-compare)
3. Ask the user to confirm deleting the originals, with a reason
4. Delete the originals on approval
