# View commands

All paths below are relative to `REPO_MEM_DIR` (the memory directory token defined in CLAUDE.md — see SKILL.md for resolution rules).

## `/repo-memory` (no args) — summary

Read `REPO_MEM_DIR/MEMORY.md`. For each indexed entry, lazily read the topic file's frontmatter to determine its type. Group by type and show count, oldest age, and each entry's description with its mtime.

## `/repo-memory list` — detailed list

Like summary, plus filename, mtime, and rough size for each memory.

## `/repo-memory show <name>` — full content

Print `REPO_MEM_DIR/<name>.md` as a code block. Resolve partial names if unambiguous; otherwise list candidates and ask.
