# Auto-memory detection

This file is a fallback spec for when the auto-memory section isn't present in your system prompt. Use it to decide what to save and how to format it.

## Categories

Watch for information worth remembering across sessions in these categories:

### user
Details about who the user is — role, goals, responsibilities, knowledge, and how they prefer to collaborate (tools, conventions, communication style). Save when you learn something new about the person.

### feedback
Guidance the user has given about how to approach work. Both corrections ("don't do X") and confirmations ("yes, that's the right call — here's why"). Save from failure AND success; confirmations matter as much as corrections, because they validate non-obvious judgment calls.

### project
Facts about ongoing work that aren't derivable from the code or git history — goals, initiatives, bugs, incidents, deadlines, stakeholders, who's doing what and why.

### reference
Pointers to where information lives in external systems — issue trackers, dashboards, Slack channels, internal docs. Save when you learn a resource exists and what it's used for.

## What NOT to save

- Code patterns, conventions, architecture, file paths, or project structure — derivable by reading the current project state.
- Git history or who-changed-what — `git log` / `git blame` are authoritative.
- Debugging solutions or fix recipes — the fix is in the code; the commit message has the context.
- Anything already documented in `CLAUDE.md`.
- Ephemeral task details: in-progress work, current conversation context.

## Format

A memory is two files: an entry in the index, and a topic file with the content.

### `MEMORY.md` (the index)

`MEMORY.md` lives at the root of `REPO_MEM_DIR`. It is a plain markdown list — no frontmatter. Each entry is one line, under ~150 characters, pointing to a topic file:

```
# Memory Index

- [Title](user_role.md) — one-line hook describing what's in the file
- [Title](feedback_testing.md) — one-line hook
```

Keep it concise: it's loaded into context on startup, so long indexes waste tokens.

### Topic files

Each memory is its own file in `REPO_MEM_DIR`, named semantically by topic (e.g. `user_role.md`, `feedback_testing.md`, `project_migration.md`). Frontmatter format:

```markdown
---
name: {{memory name}}
description: {{one-line description — used to decide relevance in future conversations}}
type: {{user | feedback | project | reference}}
---

{{memory content}}
```

For `feedback` and `project` types, structure the body as: the rule or fact, then a **Why:** line (the reason or incident behind it) and a **How to apply:** line (when/where it applies). Knowing *why* lets future agents judge edge cases instead of applying the rule blindly.

Organize semantically by topic, not chronologically. Update or remove entries that become wrong or stale — don't duplicate.

---

When you detect a memory to save, propose the write via the repo-memory skill's save flow. Both the topic file and the `MEMORY.md` index entry must be shown and confirmed together.
