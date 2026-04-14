# Extraction Manifest — Code Mode Content (for task 002)

Task 001 carved code-specific content out of the base framework files. Task 002's implementer places the carved content into `framework/modes/code/`. Each entry below lists the content block, where it originally lived, and what it represents for the mode.

Layout of the code mode is task 002's decision. This manifest is a content inventory, not a directory proposal.

## 1. Files that move wholesale (unchanged) from `framework/perspectives/` into the code mode's perspectives directory

These perspective files are already code-specific. Do NOT edit their content in task 001 — just move them in task 002 (leave them where they are for now; this branch still runs code PRDs):

- `framework/perspectives/implementer.md`
- `framework/perspectives/code-cleaner.md`
- `framework/perspectives/code-reviewer.md`
- `framework/perspectives/explorer.md`

## 2. Files that move wholesale from `framework/processes/` into the code mode's processes directory

- `framework/processes/build-cycle.md` — entirely code-domain ("writes code, writes tests, runs tests"). The task 001 context audit missed this; the architect surfaced it. Move as-is; do not edit in place.

## 3. Code-mode seed addendum

Content the code mode layers on top of the base seed:

### 3a. Commit Discipline (stronger code-specific phrasing)
The base seed now has a neutral "Recording Changes" section. The code mode may want the sharper git-specific language. Source text (from prior base `seed.md` "Commit Discipline"):

> Atomic commits — one logical change each. Explain why, not just what. A history that can be bisected is a history that can be debugged.

### 3b. AGENTS.md paragraph
Removed from base `seed.md` Shared Context section. Source text:

> AGENTS.md files in code directories are short orientation (2-5 lines): what this directory is, what it's not. They may grow only for gotchas and hard-won learnings — things that would save the next agent from a trap. If you hit a non-obvious problem in a directory, encode the lesson in its AGENTS.md. Don't pre-fill them with architecture or file listings.

### 3c. TDD as a code-mode principle
The base Verification Rigor section is now domain-neutral. The code mode should add the TDD stance: tests before implementation, behavioral tests at the boundaries, test infrastructure setup as part of verification. This lived in `framework/perspectives/implementer.md` (which is already moving wholesale — see §1) — no new copy needed unless the code mode wants a seed-level principle in addition to the implementer perspective.

## 4. Code-mode PRD process addendum

Content to layer onto `framework/processes/prd.md`:

### 4a. Green Builds section
Removed from base `processes/prd.md`. Source text:

> ## Green Builds
>
> Every task that changes code must leave all tests passing. Red builds are broken windows — they multiply quickly. Don't assume a failing test isn't yours. If tests fail when you're done, fix them before marking your step complete.

### 4b. Code Cleaning section
Removed from base `processes/prd.md`. Source text:

> ## Code Cleaning
>
> The code-cleaner applies fixes directly — it doesn't kick back to the implementer. It commits corrections for correctness issues, simplifies unnecessary complexity, and aligns with project patterns. One pass, no rounds.

### 4c. TDD specifics in the Verification Cascade
The base cascade now says: "Implementer (or whatever the active mode calls the execution role) — Operationalizes the architect's verification strategy: designs the concrete checks that prove outcomes before producing the artifact." The code mode sharpens this to TDD:

> **Implementer** — Practices TDD. Writes tests that verify outcomes before writing implementation code.

And the QA-Engineer "gap" phrasing in the base now says "looks right" vs "actually works". The code mode can sharpen back to "tests pass" vs "it actually works" if desired.

## 5. Code-mode planner addendum

### 5a. Role one-liners
The base planner dropped its role list entirely. The code mode should provide one-liners for the code-mode roles so the planner can pick between them without reading each perspective file from scratch. Source text (from prior base `planner.md` lines 15-21):

> * **implementer** — writes code (TDD: tests first), commits
> * **code-cleaner** — evaluates correctness and quality, fixes directly
> * **explorer** — traces codebases to build understanding before modification

The base planner now says: "Available roles live in the perspectives directories you have access to — base roles always, plus any the active mode adds." Base-role one-liners (architect, design-reviewer, spec-reviewer, qa-engineer, planner) are NOT in this manifest — they belong wherever the base planner chooses to surface them (currently absent, and that's fine; the planner can read perspective files directly).

### 5b. Common patterns
Removed from base `planner.md`. Source text:

> Common patterns:
> * Standard feature/bug fix: architect → implementer → code-cleaner
> * Trivial change: implementer → code-cleaner
> * Complex system change: explorer → architect → implementer → code-cleaner
> * High-level or user-facing: architect → implementer → qa-engineer → code-cleaner
> * Investigation/research: explorer or architect alone
>
> These are patterns, not a menu. Compose what fits the task.

These are the patterns the base planner now points to via: "If the active mode provides suggested pipeline patterns, read them". Task 002's implementer decides the file name and location.

## 6. Out of scope for task 002 (flagged for awareness)

- `framework/template.claude.settings.json` — task 007 handles.
- `framework/templates/prd.json` — structurally domain-neutral. If it contains code-specific example content, leave it; that's a separate cleanup.

## 7. Physical file-move summary (for task 002)

Move (unchanged) from base to code mode:
- `framework/perspectives/implementer.md`
- `framework/perspectives/code-cleaner.md`
- `framework/perspectives/code-reviewer.md`
- `framework/perspectives/explorer.md`
- `framework/processes/build-cycle.md`

Add new files to the code mode containing the content in sections 3, 4, and 5 above.

After task 002's moves land, `framework/perspectives/` contains only: `architect.md`, `planner.md`, `design-reviewer.md`, `spec-reviewer.md`, `qa-engineer.md`. And `framework/processes/` contains only `prd.md`.
