# Audit (freshness check)

All paths below are relative to `REPO_MEM_DIR` (the memory directory token defined in CLAUDE.md — see SKILL.md for resolution rules).

For each memory in `REPO_MEM_DIR`, read its content and verify any file paths or factual claims still hold (read referenced files, run greps as needed). Report whether each is accurate, partially drifted, or stale; for drift or stale entries, give a specific suggestion. End with a summary count.

This is the most expensive operation in this skill — only run when explicitly requested.
