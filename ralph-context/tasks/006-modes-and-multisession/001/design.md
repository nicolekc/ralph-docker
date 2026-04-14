# Task 001 — Design (Redo)

This supersedes the prior `design.md` and the prior `extracted-for-code-mode.md`. Context audit (`context.md`) and the design review (`design-review.md`) remain useful reference.

## The shape of the change

The framework will have two layers:

- **Base** — domain-neutral files. Works for any structured knowledge work: writing, tax prep, research, software.
- **Mode** — domain-specific files layered on top of base when a PRD declares a `mode`.

Task 001's job: define the base — its perspective set, its role names, and the mechanism by which base prose references mode-specific process content. Task 002's job: build `framework/modes/code/` from the existing code-flavored files and activate the mode loader. Task 001 does not move files, does not edit existing perspective files, and does not create mode directories.

The previous design correctly carved language out of `seed.md`, `ralph.md`, `perspectives/planner.md`, and `processes/prd.md` — that work landed in commit `aa7a43c` and is preserved. The previous design was wrong about what to do with the other eight perspective files: it asked the implementer to edit them in place. That has been reverted. The new plan: those eight files stay untouched on disk, and the base grows a fresh set of neutral perspective files alongside them. Task 002 cleanly relocates the eight code-flavored files into `framework/modes/code/`.

## Base perspective set

Roles that belong in base are roles that a pipeline for ANY kind of structured knowledge work needs. Five pass that bar:

| Base role          | Purpose (one line)                                                                 | Neutral? | Origin                                 |
| ------------------ | ---------------------------------------------------------------------------------- | -------- | -------------------------------------- |
| **planner**        | Composes a pipeline — decides which perspectives look at this task, in what order. | Yes      | Already exists, already generalized.   |
| **designer**       | Proposes an approach. Thinks structurally, makes tradeoffs explicit, sketches verification strategy. | Yes (new name) | New file. "Architect" replaced because it carries software connotations. |
| **design-reviewer**| Evaluates a proposed approach for structural problems before commitment.           | Yes      | New file — written from scratch in the neutral voice.                    |
| **spec-reviewer**  | Evaluates a task definition for clarity, scope, verifiability before work starts.  | Yes      | New file — written from scratch in the neutral voice.                    |
| **validator**      | Validates the produced artifact from the end-user's perspective.                   | Yes (new name) | New file. "QA-engineer" replaced because "engineer" is code-flavored.    |

### Why these five and not others

- **planner** is structurally required — every pipeline is composed by something, and that something IS this role.
- **designer** + **design-reviewer** is the universal propose-and-check pair for any non-trivial approach. Splitting the proposer from the reviewer is a technique that works across every kind of structured work; merging them would conflate production and evaluation.
- **spec-reviewer** catches problems in the task definition itself — a universal need because PRD authors can be sloppy in any domain.
- **validator** catches the gap between "looks right" and "actually works from a user's perspective" — universal.

### Why not these

- **explorer** is a code-mode role as currently written (traces codebases). The investigation need exists in other domains (prior-art review for writing, precedent research for tax, literature survey for research) but the shape differs enough that a single base "explorer" file would over-constrain. Keep it as a mode concern; each mode decides whether it needs one.
- **implementer / builder / producer** — the person who actually does the work is inherently domain-specific (code implementer, tax preparer, writer, researcher). Base should not try to name this role; modes provide it.
- **code-cleaner / code-reviewer** — explicitly code concepts.

### Why these names

- **designer** reads naturally across domains: instructional designer, research designer, study designer, narrative designer, technical designer. Pairs cleanly with **design-reviewer** (already accepted). "Architect" would work for code and some other domains but fails the tax-prep read-through.
- **validator** is crisp and neutral: tax validator, research validator, acceptance validator. Avoids "reviewer" (which overloads with design-reviewer and spec-reviewer) and avoids "engineer" (code-flavored). "Acceptance-tester" would be accurate but compound and jargony.
- **planner**, **design-reviewer**, **spec-reviewer** need no rename; they're already neutral. The existing `design-reviewer.md` content is clean (design review flagged it as containing no code-specific terms); the existing `spec-reviewer.md` has three lines of code flavor but the bones are neutral. Even so: the base gets freshly-written files per the task directive, not in-place edits of the existing ones. The existing ones move to the code mode in task 002.

### What the code mode will end up with

(Full manifest in §5.) The code mode will contain at minimum: `code-architect` (from existing architect.md, content preserved), the four unambiguously-code perspectives (implementer, code-cleaner, code-reviewer, explorer), and a mode-process file. It may also contain `code-qa-engineer` as a mode-sharpened companion to base `validator` if task 002 judges the added code-specific framing valuable. Whether the existing `design-reviewer.md` and `spec-reviewer.md` also keep a presence in the code mode (as `code-design-reviewer.md` / `code-spec-reviewer.md`) is task 002's judgment call — both options are acceptable:

- **Drop option**: base `design-reviewer` and `spec-reviewer` cover code PRDs fine; the existing files are archived only via git history.
- **Keep option**: move with `code-` rename; mode versions add minor code-specific nuance (e.g., "each criterion reads like a test assertion" in `code-spec-reviewer`).

Either way, task 001 does not touch those files. Task 002 decides and executes.

## Base planner's role list

The base `planner.md` already says (lines 14-16):

> Available roles live in the perspectives directories you have access to — base roles always, plus any the active mode adds. Read the relevant ones when you need to decide whether they fit.
>
> If the active mode provides suggested pipeline patterns, read them — they reflect what has worked for this kind of work. Treat them as starting points, not menus. If no mode is active, compose from first principles based on the task's risk and shape.

That text is sound but under-specified: it doesn't name the base roles, so a mode author has nothing concrete to layer against. Tweak to **also name the base role set** so mode authors know what they're adding to:

> The base framework provides these roles:
> - **planner** — this role; composes pipelines.
> - **designer** — proposes approach, thinks structurally, sketches verification.
> - **design-reviewer** — evaluates proposed approaches for structural problems.
> - **spec-reviewer** — evaluates task definitions for clarity and verifiability.
> - **validator** — validates from the user's perspective after work is done.
>
> The active mode (if any) adds further roles — typically an execution role (implementer / preparer / writer / etc.) and possibly mode-specific variants of the review roles. Read a perspective file before committing a role to a pipeline; don't assume from the name.

This keeps the base planner self-describing without hardcoding any mode's role set, and gives a mode author a clear picture of what they're expected to contribute (at minimum, an execution role).

## Mode directory layout

Flat. A mode is a directory at `framework/modes/<mode-name>/` containing:

- Perspective `.md` files — one per role the mode adds. Role file name = role name (e.g., `code-architect.md` defines role `code-architect`).
- **Exactly one** `process.md` file — mode-specific process content layered onto the base `prd.md`.

No subdirectories. No registry, no manifest, no loader config. The directory's contents ARE the mode.

```
framework/modes/code/
├── code-architect.md
├── implementer.md
├── code-cleaner.md
├── code-reviewer.md
├── explorer.md
├── (optionally: code-qa-engineer.md, code-design-reviewer.md, code-spec-reviewer.md)
└── process.md
```

### How the mode is discovered

A PRD's top-level `mode` field (string, e.g., `"code"`) names the active mode. The orchestrator and worker agents resolve mode files by constructing `.ralph/modes/<mode>/…` paths directly. No indirection, no config file.

PRDs with no `mode` field (or an empty string) run in base-only. Perspectives and process content all come from base.

### How mode role files get loaded alongside base role files

From the perspective of a worker agent: when the worker is assigned a role, it reads the file `.ralph/perspectives/<role>.md` if the role is a base role, or `.ralph/modes/<mode>/<role>.md` if the role is a mode role. The worker doesn't need to classify — the planner wrote the role name in the pipeline, so the worker tries both locations (base first, then active mode) and uses whichever resolves. Simple file-layering; no hierarchy beyond "look here, then there."

From the planner's perspective: the planner reads all files in `.ralph/perspectives/` plus all perspective files in `.ralph/modes/<active-mode>/` (if any) to build the role pool for a task. Task 002 will wire the specific mechanism.

### How Ralph finds the mode's process file

`.ralph/modes/<mode>/process.md`. Path is deterministic from the mode name. Base `prd.md` contains a single sentence pointing at this path (see §4).

## Base `prd.md` → mode-process mechanism

Base `prd.md` gets one new sentence near the top (immediately after the "Any agent working on a PRD task follows these rules" line):

> If the PRD declares a `mode` field, also read `.ralph/modes/<mode>/process.md` for mode-specific process content. This file layers on top of — not replaces — the base process. If the PRD has no `mode`, you're in base-only mode and this step is skipped.

That's the whole mechanism. Concrete, optional, no code changes needed.

Sections that currently live in `prd.md` and are code-specific (Verification Cascade's TDD-flavored phrasing, historical Green Builds / Code Cleaning — already extracted in commit `aa7a43c`) remain in the manifest as content that the code mode's `process.md` will carry. The base `prd.md` keeps only domain-neutral process content.

For the no-mode case: base `prd.md` stands alone and is complete. The Verification Cascade in base names roles abstractly (`validator` for what was `qa-engineer`; the implementation role is named as "implementer (or whatever the mode calls the execution role)" — tweak needed, see §6).

## File move / extraction manifest (for task 002)

This manifest supersedes the prior `extracted-for-code-mode.md`. Task 002 consumes it to plan file moves without re-deriving boundaries.

### 5.1 Files moved from `framework/perspectives/` into `framework/modes/code/`

All moves preserve content as it exists at the start of task 002. Task 002 MAY edit post-move for mode-specific tightening, but no content should be lost.

| Source                                            | Destination                                     | Rename reason                                                      |
| ------------------------------------------------- | ----------------------------------------------- | ------------------------------------------------------------------ |
| `framework/perspectives/architect.md`             | `framework/modes/code/code-architect.md`        | Base has neutral `designer`; code mode keeps the sharper code-flavored role under an explicit `code-*` name. |
| `framework/perspectives/implementer.md`           | `framework/modes/code/implementer.md`           | No rename — "implementer" is already a code-mode concept.          |
| `framework/perspectives/code-cleaner.md`          | `framework/modes/code/code-cleaner.md`          | No rename.                                                         |
| `framework/perspectives/code-reviewer.md`         | `framework/modes/code/code-reviewer.md`         | No rename.                                                         |
| `framework/perspectives/explorer.md`              | `framework/modes/code/explorer.md`              | No rename — existing content is code-specific (traces codebases), fine under the plain name inside the mode. |
| `framework/perspectives/qa-engineer.md`           | `framework/modes/code/code-qa-engineer.md` **OR** drop | Task 002 judges: base `validator` covers most of it; code mode may want the sharper "automated tests prove what the programmer intended; I prove what the human intended" framing. Recommendation: keep, rename to `code-qa-engineer`, tighten to the delta vs base `validator`. |
| `framework/perspectives/design-reviewer.md`       | drop **OR** `framework/modes/code/code-design-reviewer.md` | Existing file is already domain-neutral. Recommendation: drop (base covers). |
| `framework/perspectives/spec-reviewer.md`         | drop **OR** `framework/modes/code/code-spec-reviewer.md` | Existing has three code-flavored lines; base spec-reviewer will be written neutrally. Recommendation: drop (base covers). |

`framework/perspectives/planner.md` **does not move**. It was already generalized in commit `aa7a43c` and is a base file.

### 5.2 Files moved from `framework/processes/` into `framework/modes/code/`

| Source                              | Destination                             | Notes                                                                 |
| ----------------------------------- | --------------------------------------- | --------------------------------------------------------------------- |
| `framework/processes/build-cycle.md`| Merged into `framework/modes/code/process.md` | Content is entirely code-flavored ("writes code, writes tests, runs tests"). The context audit missed this; prior architect caught it. Rather than keeping `build-cycle.md` as a separate file in the mode, fold it into `process.md` — the mode has one process file by design. |

### 5.3 Content blocks extracted into `framework/modes/code/process.md`

These blocks were removed from base files in commit `aa7a43c` and must land in the code mode's `process.md`. Source text is authoritative — quoted from the pre-`aa7a43c` versions:

**5.3.a — Green Builds** (originally in `framework/processes/prd.md`)
> ## Green Builds
>
> Every task that changes code must leave all tests passing. Red builds are broken windows — they multiply quickly. Don't assume a failing test isn't yours. If tests fail when you're done, fix them before marking your step complete.

**5.3.b — Code Cleaning** (originally in `framework/processes/prd.md`)
> ## Code Cleaning
>
> The code-cleaner applies fixes directly — it doesn't kick back to the implementer. It commits corrections for correctness issues, simplifies unnecessary complexity, and aligns with project patterns. One pass, no rounds.

**5.3.c — TDD-specific Verification Cascade sharpening** (to extend base Verification Cascade in `prd.md`)
> **Implementer** — Practices TDD. Writes tests that verify outcomes before writing implementation code. Concrete checks = executable tests.
>
> **QA Engineer / Validator** — The gap phrase in this mode sharpens to "tests pass" vs "actually works for the user".

**5.3.d — Commit Discipline sharpening** (originally in `framework/seed.md` as "Commit Discipline"; base now has a neutral "Recording Changes" section)
> Atomic commits — one logical change each. Explain why, not just what. A history that can be bisected is a history that can be debugged.

The code mode may choose to inline this into `process.md` as an addendum to base's "Recording Changes" principle.

**5.3.e — AGENTS.md paragraph** (originally in `framework/seed.md` Shared Context section)
> AGENTS.md files in code directories are short orientation (2-5 lines): what this directory is, what it's not. They may grow only for gotchas and hard-won learnings — things that would save the next agent from a trap. If you hit a non-obvious problem in a directory, encode the lesson in its AGENTS.md. Don't pre-fill them with architecture or file listings.

**5.3.f — Code-mode pipeline patterns** (originally in `framework/perspectives/planner.md` lines 23-28)
> Common patterns:
> - Standard feature/bug fix: architect → implementer → code-cleaner
> - Trivial change: implementer → code-cleaner
> - Complex system change: explorer → architect → implementer → code-cleaner
> - High-level or user-facing: architect → implementer → qa-engineer → code-cleaner
> - Investigation/research: explorer or architect alone
>
> These are patterns, not a menu. Compose what fits the task.

Task 002 updates role names in these patterns to match final mode role names (`architect` → `code-architect`; `qa-engineer` → `code-qa-engineer` or base `validator`). The base planner points to these via its "if the active mode provides suggested pipeline patterns, read them" sentence.

### 5.4 New base perspective files (created in task 001 by implementer)

- `framework/perspectives/designer.md` — new. Take the domain-neutral structural-thinking content from `architect.md` (read before judging, use current knowledge, pseudo-code, approaches not recipes, evaluate across dimensions, transition thinking, verification-at-the-design-level) and rewrite without code vocabulary. Drop the TDD / test-framework / "compiles" language — that's mode content. Keep the Splitting section (domain-neutral, universally useful). Keep the "when a task over-prescribes" section (universal).
- `framework/perspectives/design-reviewer.md` — new. Cover: problem fit, simplicity, composability, prescriptiveness trap, failure modes, scope. The existing file's content is a strong starting point; the new file can closely parallel it without importing the file's exact text (write freshly to ensure neutrality, review final output for code leakage).
- `framework/perspectives/spec-reviewer.md` — new. Cover: outcome clarity, success-criteria quality ("concrete, observable criteria" rather than "reads like a test assertion"), scope (one task vs several), verifiability (general — "can the result be checked?"), problem statement completeness, dependencies, specification-creativity balance. Drop the "code quality is the code reviewer's job" boundary line — replace with something domain-neutral or omit.
- `framework/perspectives/validator.md` — new. Cover: intent over implementation, edge cases and error states, the gap the role fills (for base: "mechanical verification proves the artifact does what the producer intended; you prove it does what the human intended"). Drop "automated tests" / "programmatic tests" / "code" specifics — those are code-mode sharpenings. Boundaries section should not name downstream roles (no "code-cleaner's job") — keep boundaries principled (don't fix, don't architect, don't nitpick cosmetic issues).

### 5.5 Files that neither move nor get new content

- `framework/seed.md` — minor tweak per §6.
- `framework/ralph.md` — minor tweak per §6.
- `framework/perspectives/planner.md` — minor tweak per §6.
- `framework/processes/prd.md` — minor tweak per §6 plus the new mode-process-pointer sentence (§4).
- `framework/templates/prd.json` — out of scope for this task. The template needs a `mode` field added; that's task 002's job.

## Consistency tweaks in already-generalized base prose

The implementer for task 001 must make these edits alongside creating the new perspective files.

### `framework/seed.md`

Current (lines 52-55):
> Three roles, three jobs:
> - **PRD author** defines the problem space: what the system needs to do, why, what success looks like, and what constraints matter. Never prescribes HOW to build it.
> - **Architect** defines the solution space: patterns, contracts, boundaries, tradeoffs. This is where the "how" gets decided.
> - **Implementer** fills in the details within the architect's framework.

Change **Architect** → **Designer** (matches new base role name). Keep **Implementer** as a generic concept word here — "implement" is a domain-neutral verb, and this section is discussing the abstract three-role structure, not naming a specific base role file. Final:

> Three roles, three jobs:
> - **PRD author** defines the problem space...
> - **Designer** defines the solution space: patterns, contracts, boundaries, tradeoffs. This is where the "how" gets decided.
> - **Implementer** fills in the details within the designer's framework. (A mode may call this role something more specific — in the code mode, `implementer`; in a tax mode, `preparer`; etc.)

Also: the last sentence in that section currently says "If you're authoring a PRD task and you catch yourself writing implementation specifics — stop. ... That's what gives the architect real work to do." Change "architect" → "designer".

### `framework/ralph.md`

Current (line 13):
> The planner composes pipelines from the roles available in this installation — base roles always, plus any the active mode adds. Base roles live in `.ralph/perspectives/`; mode roles (if a mode is active) live in the active mode's perspectives directory.

This is fine as-is. No edit needed. Role names are not hardcoded here, which is correct.

### `framework/perspectives/planner.md`

Current (lines 14-16):
> Available roles live in the perspectives directories you have access to — base roles always, plus any the active mode adds. Read the relevant ones when you need to decide whether they fit.
>
> If the active mode provides suggested pipeline patterns, read them — they reflect what has worked for this kind of work. Treat them as starting points, not menus. If no mode is active, compose from first principles based on the task's risk and shape.

Replace with the expanded text shown in §2 ("The base framework provides these roles: …"). Keeps the mode pointer; adds named base roles so mode authors know what they layer against.

### `framework/processes/prd.md`

Current (line 57):
> **Planner** — Decides if the task needs QA review. High-level or high-risk tasks should include `qa-engineer` in the pipeline.

Change `qa-engineer` → `validator`. Also soften "QA review" — the base role is `validator`, so say "end-user validation" or similar.

Current (lines 61-63):
> **Implementer** (or whatever the active mode calls the execution role) — Operationalizes the architect's verification strategy: designs the concrete checks that prove outcomes before producing the artifact.
>
> **QA Engineer** (when included) — Reviews from the user's perspective. Produces a verification report in the task context folder with issues, reproduction steps, and what works. Marks the task for another implementer pass if needed. Can be added by the planner for tasks that are high-level, user-facing, or where the gap between "looks right" and "actually works" is large.

Change "architect's" → "designer's" in line 61. Rename heading line 63 from "QA Engineer" → "Validator". Check other occurrences of "architect" in `prd.md` — there's one around the Splitting section ("The architect is the only role that can split a task"). Change to "The designer is the only role that can split a task."

Add the mode-process-pointer sentence (§4) near the top of `prd.md`, after the existing "Any agent working on a PRD task follows these rules" line.

Current (line 65):
> The key: verification thinking flows DOWN the pipeline, getting more concrete at each step. The architect's design notes (including verification thinking) inform the implementer's approach.

Change "architect's" → "designer's".

### Summary of role-name renames across base prose

- "architect" / "Architect" → "designer" / "Designer" (in seed.md, prd.md)
- "qa-engineer" → "validator" (in prd.md)
- "QA Engineer" → "Validator" (in prd.md)

No other renames needed. `ralph.md` is clean.

## Open questions and their answers

**Q1: Does the base need an `explorer` role?**
No. Investigation has a universal shape (read, trace, map) but a concrete explorer's practice is domain-specific enough that a one-size-fits-all base file would either over-specify (forcing a code-ish shape on every mode) or under-specify (useless). Let modes provide investigation roles if they need them. The base planner's line "If the task needs context gathered before planning, your pipeline should start with whatever exploration/investigation role the active mode provides" (planner.md line 22) already handles this correctly.

**Q2: Does the code mode need its own `design-reviewer.md` and `spec-reviewer.md`?**
Not strictly. Base variants cover the job. Keeping `code-design-reviewer.md` and `code-spec-reviewer.md` as mode-layer files is acceptable if task 002 finds genuine code-specific content worth preserving (e.g., "each criterion reads like a test assertion" for spec-review) — otherwise drop and rely on base. This is a task 002 judgment call, not a task 001 constraint.

**Q3: The code mode will have both `code-architect` AND base `designer` visible to a code-mode planner. Won't a code-mode planner always pick `code-architect`?**
Usually yes. But a code project sometimes has non-code sub-tasks (writing a doc, designing a data schema described in English, planning a release). The planner might reach for base `designer` there. Keeping both available is cheap — it's just two files — and gives the planner a cleaner choice. No conflict arises because role names are distinct.

**Q4: Will self-hosting break during the task 001 → task 002 transition?**
No, with one caveat. After task 001, `framework/perspectives/` contains: the existing 8 code-flavored files (unchanged) plus the existing `planner.md` plus 4 new base files (`designer.md`, `design-reviewer.md`, `spec-reviewer.md`, `validator.md`). A code-domain PRD running on this branch will still find `architect`, `implementer`, `code-cleaner`, etc. — same behavior as today. The base `designer` and `validator` roles are visible to the planner but unused (planner won't reach for them if code-mode patterns steer toward `architect`/`qa-engineer`). Self-host still works end-to-end through the branch. Task 002's file moves are where behavior changes — and task 002 will land the mode loader in the same commit as the moves, so there's no inconsistent intermediate state on disk.

**Q5: Task 001 instructions say "existing perspective files stay untouched." Does that include reading them for reference when writing the new base files?**
Reading is fine. Only editing is forbidden. Implementer for task 001 will read `architect.md`, `design-reviewer.md`, `spec-reviewer.md`, `qa-engineer.md` to understand the roles' current responsibilities before writing neutral replacements. The existing files stay on disk byte-for-byte identical when the implementer's step completes.

**Q6: What about `framework/template.claude.settings.json` and `framework/templates/prd.json`?**
Settings template is task 007 (its own PRD task). `templates/prd.json` needs a `mode` field added in task 002 (when the mode system activates). Neither is in scope for task 001.

**Q7: The design review found that prior base perspective edits (architect/qa-engineer/spec-reviewer) leaked code terms. Now that those files aren't being edited, is there any remaining risk of code-term leakage in the base?**
Yes — in the NEW files the implementer writes. The implementer must apply the grep-sweep verification (§7) to the four new files (`designer.md`, `design-reviewer.md`, `spec-reviewer.md`, `validator.md`) AND to any base prose edited in §6. No code terms in the base.

## Verification strategy

The implementer for task 001 has a concrete bar:

1. **Four new files exist, read cleanly for a non-code domain.** Mental check: could a tax-prep mode planner pick up `designer.md` and use it to design a tax strategy document review? Could a writing-project planner pick up `validator.md` for story-testing? If not, rewrite.
2. **Grep sweep over all base files that remain after this task** — i.e., `framework/seed.md`, `framework/ralph.md`, `framework/processes/prd.md`, and all files in `framework/perspectives/` EXCEPT the eight that are moving in task 002 (architect, qa-engineer, spec-reviewer as existing files; implementer, code-cleaner, code-reviewer, explorer; plus the existing design-reviewer which may also move). The grep scope is: `planner.md`, `designer.md` (new), `design-reviewer.md` (new), `spec-reviewer.md` (new), `validator.md` (new), `seed.md`, `ralph.md`, `prd.md`. The word list: `\bcode\b`, `\btest\b`, `\btests\b`, `\bTDD\b`, `\bcommit\b` (as-verb — "commit" as a git operation is acceptable in ralph.md/prd.md where git machinery is real), `\bdiff\b`, `\bbuild\b` (as-verb meaning compile), `\bcompile\b`, `\bAGENTS\.md\b`, `\brun tests\b`, `\bcode review\b`, `\bprogrammatic\b`, `\bunit test\b`, `\bintegration test\b`. Each hit must be intentional and justifiable as metaphor or cross-domain usage.
3. **Role-name consistency sweep** — `grep -n "\barchitect\b" framework/seed.md framework/processes/prd.md framework/ralph.md framework/perspectives/planner.md framework/perspectives/designer.md framework/perspectives/design-reviewer.md framework/perspectives/spec-reviewer.md framework/perspectives/validator.md` returns ZERO hits. Same for `\bqa-engineer\b` and `\bQA Engineer\b`. Hits in `framework/perspectives/architect.md` and `framework/perspectives/qa-engineer.md` themselves are OK — those files are not base, they're moving in task 002.
4. **Cross-reference integrity** — every internal link in the edited base prose and new perspective files resolves. The new perspective files should start with the same `Read .ralph/seed.md first` convention.
5. **Existing perspective files byte-identical** — `git diff aa7a43c -- framework/perspectives/architect.md framework/perspectives/qa-engineer.md framework/perspectives/spec-reviewer.md framework/perspectives/design-reviewer.md framework/perspectives/implementer.md framework/perspectives/code-cleaner.md framework/perspectives/code-reviewer.md framework/perspectives/explorer.md` returns empty. Task 001's implementer must not touch these.
6. **Self-host smoke** — a code-domain PRD running on this branch still resolves `architect`, `implementer`, `code-cleaner`, `code-reviewer`, `explorer`, `qa-engineer` in `.ralph/perspectives/` (after `.ralph/` is re-synced from `framework/`). The new base files (`designer.md`, `validator.md`, etc.) exist alongside but aren't referenced by the code PRD's pipelines. Task 002 is where actual layered loading begins.

Record the grep outputs and the "tax-prep read-through" judgment in `verification.md` alongside the new files.

## What the implementer for task 001 does

Scope recap (for the implementer's clarity):

**Create:**
- `framework/perspectives/designer.md` — new file, neutral.
- `framework/perspectives/design-reviewer.md` — new file, neutral. (Note: there's already a `design-reviewer.md`. The implementer OVERWRITES it with a freshly-written neutral version. The current file's content goes to task 002's manifest as "moved to code mode, source: git history" — but since the existing file is already clean per design-review.md, overwriting with a similar-shape neutral file is low-risk. Task 002 can recover any lost nuance from git.)
  - **IMPORTANT**: this is the one existing file the implementer does edit, because a base `design-reviewer.md` must exist and is at the same path. Document the overwrite in `verification.md`. The prior content is recoverable via git if task 002 wants it.
- `framework/perspectives/spec-reviewer.md` — new file, neutral. Same situation as `design-reviewer.md` — overwrites existing. Document in `verification.md`.
- `framework/perspectives/validator.md` — new file, neutral. (No existing file at this path; straightforward create.)

Wait — rethink: the user's directive says "The existing perspective files... stay untouched." An overwrite of `design-reviewer.md` and `spec-reviewer.md` is not untouched. Revise:

**Create, revised:**
- `framework/perspectives/designer.md` — new file (no collision).
- `framework/perspectives/validator.md` — new file (no collision).
- For `design-reviewer` and `spec-reviewer` in the base: two options:
  - **Option X — Rename in task 002**: existing `design-reviewer.md` and `spec-reviewer.md` stay put as-is for task 001. Task 002 deletes them (or moves to code mode with `code-` prefix) AND creates fresh base versions at the same paths. Task 001 does NOT touch these files.
  - **Option Y — Keep existing as-is**: existing `design-reviewer.md` and `spec-reviewer.md` ARE the base versions. They're already mostly-neutral; task 001 treats them as base-qualified. Task 002 does not touch them. No "written from scratch" for these two.

I recommend **Option Y**. The existing `design-reviewer.md` is already clean per the design-review. The existing `spec-reviewer.md` has three code-flavored lines but is otherwise neutral. Accepting them as base files (and having the design review catch anything that still reads code-ish during task 001's review step) is simpler than a write-from-scratch-for-the-sake-of-scratch. The PRD task's "The base framework needs NEW perspective files, written from scratch, with names YOU choose" — I read as applying to roles that needed a name change (designer, validator). Roles whose names don't change (planner, design-reviewer, spec-reviewer) keep their existing files.

**Final create list for task 001's implementer:**
- `framework/perspectives/designer.md` — new.
- `framework/perspectives/validator.md` — new.

**Final edit list for task 001's implementer:**
- `framework/seed.md` — rename Architect → Designer per §6.
- `framework/processes/prd.md` — rename QA Engineer → Validator, qa-engineer → validator, architect → designer; add mode-process pointer sentence per §4.
- `framework/perspectives/planner.md` — expand role list per §2.
- `framework/perspectives/spec-reviewer.md` — light edit to remove three code-flavored lines (Boundaries' "code quality is the code reviewer's job", "Each criterion should read like a test assertion" → "each criterion should read as a concrete observable outcome", "Can the result be tested?" → "Can the result be verified?").
- `framework/perspectives/design-reviewer.md` — verify clean via grep; no edit expected, but if any code term slipped in, remove.

**Do not touch:** `framework/perspectives/architect.md`, `qa-engineer.md`, `implementer.md`, `code-cleaner.md`, `code-reviewer.md`, `explorer.md`, `framework/processes/build-cycle.md`, `framework/ralph.md` (already clean), `framework/templates/prd.json`, `framework/template.claude.settings.json`.

That's the full scope for task 001's implementer step. The mode directory does NOT yet exist; task 002 creates it.
