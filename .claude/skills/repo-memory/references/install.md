# Install flow

Idempotent — propose each item only if it's not already done.

The goal: set up `REPO_MEM_DIR/MEMORY.md` (default `REPO_MEM_DIR: .memory`).

Propose to the user, for whichever of these aren't done:

- **Directory** — create `REPO_MEM_DIR`, or let the user specify a different path instead of the default `.memory`
- **Index file** — `REPO_MEM_DIR/MEMORY.md` (empty, or populated with migrated content)
- **CLAUDE.md `## Memory` section** — defines `REPO_MEM_DIR` and points to the index. Explain why: so future agents read existing memories on startup and know where to write new ones
- **Existing memories in the built-in location** — list them. Recommend migrating so they're versioned with the project. Explain the tradeoff if they don't: orphaned in `~/.claude/`, invisible to the repo
- **If `autoMemoryEnabled: false`** — Claude Code's auto-memory is off, so detection instructions aren't injected into the system prompt. Offer to add detection guidance inline in the CLAUDE.md `## Memory` section, using the same categories as the skill description (role/preferences, corrections, project facts, external references). That way this skill still fires without the built-in feature enabled.

Take the actions the user confirms.

## Migration procedure

1. Copy each file to `REPO_MEM_DIR`
2. Verify the copies match the originals (byte-compare)
3. Ask explicit user confirmation before deleting the originals
4. Delete the originals on approval
