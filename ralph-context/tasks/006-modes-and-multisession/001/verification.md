# Task 001 — Verification

## Grep sweep over edited base files

Searched for: `code`, `test`, `tests`, `commit`, `TDD`, `build`, `code review`, `AGENTS.md`, `unit tests`, `tested`, `run tests`

Remaining hits, all intentional and domain-neutral:

- `framework/seed.md:53` — "HOW to build it" — metaphor for construction (Respect Role Boundaries section). Valid for any domain.
- `framework/perspectives/planner.md:28` — "how to build it" — metaphor in What You Avoid. Valid for any domain.
- `framework/processes/prd.md:22` — "commit the PRD update" — refers to the git machinery used for multi-agent coordination. Git-level machinery survives across modes; this is not a code-mode concern.

No hits for: `TDD`, `AGENTS.md`, `tests? pass`, `code review`, `tested`, `unit tests?` in any of the four edited files.

## Tax-preparation read-through

Reading seed, ralph, planner, prd as if building a tax preparation pipeline:

- seed.md: "Own the Quality Loop", "Recording Changes", "Read Before Judging", "Verification Rigor" — all read naturally. "Verify the change works (whatever 'works' means for this artifact)" fits checking a return against source documents. "Produce the artifact, exercise it, prove it works" fits filing a return through a validator.
- ralph.md: Roles section now abstracts to "base roles + mode roles". Task Completion Assessment bullets are domain-neutral.
- planner.md: Role-list is removed; the planner is told to read available perspectives. Common patterns is a two-sentence pointer to the active mode.
- prd.md: Verification Cascade uses "verification", "concrete checks", "looks right vs actually works". Completion Assessment uses "required inputs, credentials, services" instead of API keys.

No remaining code-specific content that would confuse a tax-domain (or research-domain, or writing-domain) reader.

## Perspectives directory state

`framework/perspectives/` still contains all 9 perspective files (including code-specific: implementer, code-cleaner, code-reviewer, explorer). Per the architect's design, task 001 does NOT physically move these — task 002 does. This keeps the branch runnable for existing code PRDs while the mode system is built out.

## Cross-reference integrity

All pointers in edited base files still resolve:
- `seed.md:5` → `.ralph/perspectives/`, `.ralph/processes/prd.md`
- `ralph.md:8` → `.ralph/processes/prd.md`
- `ralph.md:13` → `.ralph/perspectives/`
- `ralph.md:29` → `.ralph/processes/prd.md` (via "Completion Assessment" section name)

No dangling references.

## Self-host sanity

`.ralph/` is stale relative to `framework/` (it's the installed copy, regenerated separately). This branch's behavior isn't affected by task 001's edits until the install flow or a sync lands. Task 002 is where the two-layer system actually runs. Flagged per architect's guidance.
