# Task 006 — Easy Install: Brainstorming

Architect decides the actual mechanism. Capturing the vision + one real constraint.

## Vision
From any project, user tells Claude "install Orca from <github URL>" and it happens — no manual shell commands.

## Bootstrap constraint
The install flow has to work on machines where Orca isn't yet installed. A Claude Code skill can't be "the" entry point unless there's some way to get the skill on the machine first (curl one-liner, manual copy, or an existing skill the user already has). Worth deciding before picking a mechanism.

## Three states to handle
- **Fresh**: no `.orca/` and no `.ralph/` → install from scratch
- **Upgrade**: `.orca/` exists → refresh framework files, leave user content alone
- **Rename migration**: `.ralph/` exists (pre-rename install) → `git mv` to orca paths then upgrade

## Mechanism direction
Use April 2026 skill-install patterns (e.g. openclaw-style) — the ecosystem made this easy, lean on it instead of reinventing. The architect should survey what's current.

## install.sh
Delete it. The new flow replaces it entirely.

## Don't re-create dead dirs
`.ralph-tasks/` is a ghost — nothing actually writes to it (see task 005). Don't scaffold `.orca-tasks/` in the new install flow. Same story for `ralph-logs/` unless bash-loop mode is being kept.
