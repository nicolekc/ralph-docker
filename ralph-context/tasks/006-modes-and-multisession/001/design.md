# Task 001 — Generalize Base Framework: Design

## The shape of the change

The base framework should read as if it were written for any structured knowledge work — writing a book, preparing a tax return, running a research project, building software. The current base presumes "software project" hard enough that whole sections (Green Builds, Code Cleaning, TDD) only make sense there.

The fix is a layered model, introduced conceptually in this task even though the mode mechanism itself lands in task 002:

- **Base** — domain-neutral principles, the pipeline machinery, the role set that any structured work needs.
- **Mode** — domain-specific principles, domain-specific roles, and the pipeline patterns that are natural for that domain.

Task 001 does the carve-out. Task 002 builds the loader and moves the extracted content into `framework/modes/code/`. This means task 001 must produce two things:

1. The edited base files (seed, ralph, planner, prd).
2. A manifest of what must land in the code mode — precise enough that task 002's implementer can place each piece without re-deriving the boundary.

The carve-out is a single coherent design decision across four files, so this task should stay together. It has no separable concerns that would benefit from splitting.

## The vocabulary

The base uses three neutral terms consistently:

- **artifact** — whatever the work produces (code, a document, a filing, a dataset). Replaces "code".
- **verification** — whatever proves the work is correct (tests, review, human read-through, dry run). Replaces "tests pass" / "runs green".
- **record the change** — whatever persists the work (commit, save, file). Replaces "commit" where the language must stay general.

The base may refer to commits/tests/code in the one place we intentionally ground it — CLAUDE.md and how to run Ralph — but those live outside the four files being generalized here. Inside seed/planner/ralph/prd, the neutral vocabulary holds.

Keep the existing Ralph-internal vocabulary that is already domain-neutral: pipeline, task, role, perspective, PRD, signoff, mode (new).

## Per-file changes

### `framework/seed.md`

- **Own the Quality Loop** — drop "run tests" from the parenthetical, drop "survive a code review". Replace with verification-neutral phrasing: "verify the change works (whatever 'works' means for this artifact)" and "would this survive a careful second reading by someone who doesn't know what I was trying to do".
- **Commit Discipline** — this whole section is code-flavored. Rename to **Recording Changes** (or equivalent) and generalize: one logical change per recorded step, explanatory rationale, a trail that can be followed backward. Keep it short.
- **Read Before Judging** — the principle is general but the language is code-coded ("cite file:line", "code you haven't read"). Generalize to "read the relevant material before forming opinions; cite sources precisely". "Code that works in isolation but breaks the whole" becomes "a change that works in isolation but breaks the whole".
- **Verification Rigor** — generalize. "Build the thing, run the thing" becomes "produce the artifact, exercise it, prove it works". The test-framework example generalizes to "if verification machinery is broken, fixing it IS part of verification".
- **Shared Context** — the AGENTS.md paragraph (lines 67) is code-specific ("AGENTS.md files in code directories"). Move this entire paragraph to the code mode's seed addendum. The preceding paragraphs about task directories stay.

Everything else in seed (Fix the Root Cause, Stay in Scope, Keep It Simple, Autonomy, Proportionality, Respect Role Boundaries) is already domain-neutral.

### `framework/ralph.md`

- **Roles section** — do not hardcode the role list here. Ralph's role set is composed from: base roles (planner, architect, design-reviewer, spec-reviewer, qa-engineer) plus whatever the active mode contributes. Replace the explicit list with a principle: "The planner composes pipelines from the roles available in this installation — base roles always, plus any the active mode adds." Include a one-line pointer: "Base roles are in `.ralph/perspectives/`; mode roles (if a mode is active) are in the mode's perspectives directory." The exact directory layout is task 002's concern — the language here just needs to tolerate it.
- **Execution invariants** — general already. Keep.
- **Task Completion Assessment** — general already. Keep. The "Always give the human running instructions" line is fine — "run" is broad.
- **Subagent Mode** — general. Keep.

The specific role descriptions that say "writes code, runs tests, commits" must leave the base file entirely. They belong to the code mode's role definitions, not here.

### `framework/perspectives/planner.md`

- **Role list** (lines 15-21) — remove the hardcoded list of implementer / code-cleaner / explorer and their code-flavored one-liners. In the base, describe what the planner does and leave role descriptions to each perspective file. A single sentence suffices: "Available roles live in the perspectives directories you have access to — base roles always, plus any the active mode adds. Read the relevant ones when you need to decide whether they fit."
- **Common patterns** (lines 23-28) — this is the key cross-cutting decision. The patterns currently listed are code-domain patterns and don't belong in the base. See the next section for how this works after the carve-out.

### Planner's Common patterns — the mechanism

The mode owns its patterns. Task 002's `framework/modes/code/` will contain a file (the implementer there will decide the exact filename and layout) that holds the code-domain pipeline patterns currently in planner.md lines 23-28.

In the base planner, replace the "Common patterns" section with two sentences that direct the planner to the active mode's patterns file when one exists:

> If the active mode provides suggested pipeline patterns, read them — they reflect what has worked for this kind of work. Treat them as starting points, not menus. If no mode is active, compose from first principles based on the task's risk and shape.

This keeps the base free of code specifics, lets modes suggest patterns without the base knowing anything about them, and preserves the "patterns not recipes" spirit. The base planner doesn't need to know how mode files are named or located — task 002 will make the mode's pattern file discoverable through the same loading mechanism it uses for perspectives.

### `framework/processes/prd.md`

- **Verification Cascade** (lines 53-65) — the machinery is general but the leaf descriptions are code-flavored. Generalize: architect thinks about verification strategy, implementer (or whatever the mode calls the execution role) operationalizes it, QA validates from the user's perspective. Drop "TDD" and "tests pass" from the base; those are the code mode's concrete realization of the general cascade. The sentence "The implementer's tests are the concrete realization of the architect's strategy" becomes "The implementer's verification work is the concrete realization of the architect's strategy".
- **Green Builds** (lines 86-88) — this entire section is code-specific. Move it to the code mode's addendum to the PRD process. In the base, replace with one domain-neutral line if anything — the Verification Cascade already carries the principle.
- **Code Cleaning** (lines 90-92) — entire section is code-specific (the role doesn't even exist in base). Move to the code mode. The base doesn't need to describe a role it doesn't have.
- **Completion Assessment** (lines 103-130) — general. The "API keys" example is code-flavored but clearly exemplary; soften it to something domain-neutral ("required inputs, credentials, services").
- Everything else in prd.md is already general.

## What task 002's implementer will extract into the code mode

The implementer for task 002 will place these items into the code mode. Task 001 just carves them out:

1. **Code-specific seed addendum** — the AGENTS.md paragraph from seed's Shared Context section; the Commit Discipline phrasing if the code mode wants the stronger "atomic commits" language; TDD as a code-mode principle.
2. **Code-mode PRD process addendum** — Green Builds section; Code Cleaning section; the TDD/tests-pass specifics of the Verification Cascade.
3. **Code-mode role descriptions** — implementer, code-cleaner, code-reviewer, explorer (four existing perspective files move wholesale from `framework/perspectives/` into the code mode).
4. **Code-mode planner pattern file** — the four pipeline patterns from planner.md lines 24-28 ("Standard feature/bug fix", "Trivial change", "Complex system change", "High-level or user-facing", "Investigation/research").
5. **Code-mode planner role descriptions** — the one-line descriptions of implementer / code-cleaner / explorer that are currently in planner.md lines 16-18 and 21. (The architect, spec-reviewer, design-reviewer, qa-engineer one-liners may stay in the base planner because those roles are base roles — but rewrite them to be domain-neutral.)

Task 002 decides the file layout and loader. Task 001 only needs to ensure the carved content is preserved somewhere the implementer can find it when they go looking. Easiest vehicle: a short handoff note in this task's folder (`extracted-for-code-mode.md`) that lists the content blocks and where each originally lived. The implementer for task 001 should produce that note alongside the edited base files — it's the manifest task 002 will consume.

## Open question and its answer

**What about the code-flavored file `framework/processes/build-cycle.md`?** Read it: it's entirely code-domain ("Writes code, writes tests, runs tests"). The task 001 context audit doesn't list it. It should move to the code mode too. Flag this for the implementer — if build-cycle.md survives anywhere, it survives only inside the code mode. The context audit missed it; the architect's job is to surface that.

**What about `framework/template.claude.settings.json` and `framework/templates/prd.json`?** Out of scope for this task. Settings template is task 007. The PRD template is domain-neutral in structure; if it contains code-specific example content, flag it and leave it alone — that's a separate cleanup.

## Verification strategy

The verification bar is "read the four files as if building a tax preparation pipeline and nothing reads strange." That's a judgment read-through, not a test suite. But the implementer can anchor it concretely:

1. **Grep sweep over the edited base files** — the base should contain zero hits for a code-terminology wordlist: `\bcode\b`, `\btest\b`, `\btests\b`, `\bcommit\b`, `\bTDD\b`, `\bdiff\b`, `\brun tests\b`, `\bbuild\b` used as a verb meaning "compile", `\bcode review\b`, `\bAGENTS\.md\b`. Any hit must be intentional and justifiable as domain-neutral usage (e.g., "build the thing" as metaphor — but prefer to replace even these).
2. **Role list consistency** — the base perspectives directory (`framework/perspectives/`) contains exactly the base roles after task 001 carves but before task 002 creates the mode: architect, planner, design-reviewer, spec-reviewer, qa-engineer. (Implementer, code-cleaner, code-reviewer, explorer stay physically where they are for this task — task 002 relocates them. Task 001 does NOT delete them, because the framework is self-hosted and removing them before the mode exists would break current PRDs running on this branch.) Flag this clearly in the handoff: task 001's job is the textual generalization and the extraction manifest; the physical file moves of the code-perspective `.md` files are task 002's.
3. **Cross-reference integrity** — any internal pointer in the edited base files (`read .ralph/processes/prd.md`, etc.) still resolves. No dangling references to files the mode now owns.
4. **Self-host sanity** — this repo uses the framework on itself. After task 001's edits, `.ralph/` is still stale (it's regenerated from `framework/` separately), so behavior on this branch isn't affected yet. That's fine. Task 002 is where the loader lands and the two-layer system actually runs. Flag this so the implementer doesn't spend time trying to verify end-to-end execution of the new layering from task 001 alone — it literally can't be verified end-to-end until 002 lands.

## What the implementer for this task needs to know

- Do not delete the code-specific perspective files (`implementer.md`, `code-cleaner.md`, `code-reviewer.md`, `explorer.md`) in this task. Task 002 moves them. Leaving them in place means this branch still runs existing code-domain PRDs while tasks 001 and 002 land.
- The edits are textual. Four files change: `framework/seed.md`, `framework/ralph.md`, `framework/perspectives/planner.md`, `framework/processes/prd.md`. Plus the new handoff note at `ralph-context/tasks/006-modes-and-multisession/001/extracted-for-code-mode.md`.
- TDD doesn't fit naturally here — these are prose edits, not code. The verification is the grep sweep and the tax-preparation read-through described above. Do both and record the outcomes briefly in the task folder.
- Keep the tone. The base framework files have a specific voice — terse, principle-stating, trusting the reader. Don't pad with hedges or "note that" preambles while generalizing.
- If you notice the context audit missed something (like `build-cycle.md` above), add it to the extraction manifest rather than editing it in place.
