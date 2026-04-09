# Install flow

Propose adding a `## Memory` section to `CLAUDE.md` and creating `REPO_MEM_DIR/MEMORY.md`. The section should contain a ``REPO_MEM_DIR: `.memory/` `` line plus brief prose telling readers where to read the index and that writes are confirmed. `.memory/` is the default; the user can pick a different path in their reply, in which case substitute it on the `REPO_MEM_DIR:` line only.

If any existing memories live in the default location, they need to be migrated. Include them in the install proposal and explain the tradeoff: migrating moves them into the repo so they're versioned alongside the project; not migrating leaves them orphaned in the default location. On approval, copy each file, verify, then delete the originals.

If the user denies install, cancel the save. The skill can't operate without it.
