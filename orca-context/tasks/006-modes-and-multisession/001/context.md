# Task 001 — Generalize Base Framework: Brainstorming

Architect decides the actual changes. This is an audit of what's code-specific vs general today.

## File-by-file audit

**seed.md** — mostly general, but code-flavored:
- "would this survive a code review" (line 12) — code-specific
- "Atomic commits" / "Commit Discipline" section (lines 14-16) — code-specific
- "Read Before Judging" references "code you haven't read", "cite specific file:line" (line 20) — code-flavored but the principle is general
- "Verification Rigor" references "test framework", "build the thing, run the thing" (lines 71-73) — code-flavored
- Sections that are already fully general: Fix Root Cause, Stay in Scope, Keep It Simple, Autonomy, Proportionality, Respect Role Boundaries, Shared Context

**planner.md** — general structure, code-specific content:
- Role list (lines 15-21) hardcodes code roles: implementer, code-cleaner, explorer
- "Common patterns" (lines 24-28) are all code pipelines: "Standard feature/bug fix", "Trivial change"
- The thinking framework (lines 10-12) is general

**ralph.md** — general structure, code-specific roles:
- Roles section (lines 13-25) hardcodes: implementer, code-cleaner, code-reviewer, explorer
- "Writes code, runs tests, commits" in role descriptions
- Everything else (startup, execution invariants, dispatch, completion assessment) is general

**prd.md** — mostly general, a few code references:
- "Green Builds" section (lines 86-88) — entirely code-specific
- "Code Cleaning" section (lines 90-92) — entirely code-specific
- Verification cascade (lines 57-63) references TDD, "tests pass"
- Pipeline model, task states, splitting, durable context, signoff gates — all general

## Perspectives: which stay in base, which move to mode

**Stay (general)**: architect, planner, design-reviewer, spec-reviewer, qa-engineer
**Move to code mode**: implementer, code-cleaner, code-reviewer, explorer

Note: planner stays but its role list and patterns need to come from the active mode rather than being hardcoded.
