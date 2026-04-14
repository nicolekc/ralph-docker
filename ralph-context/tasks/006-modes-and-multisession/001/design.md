# Task 001 — Design (v3, minimum viable)

Prior passes (v1, v2) over-engineered this. This version is tight: smallest base that makes Ralph functional on a non-code PRD, one flat perspectives dir, one MODE.md per mode, one pointer sentence in base `prd.md`.

## 1. Base role set

Two roles. That's all base needs to be functional.

| Role        | Purpose (one line)                                                                  | Why in base                                                                                                           |
| ----------- | ----------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| **planner** | Composes the pipeline — decides which perspectives look at this task, in what order. | Structurally required. Every pipeline is composed by something, and that something IS this role. Already neutral, stays as-is. |
| **drafter** | Proposes an approach and sketches how the result will be verified before anyone commits to work. | Every non-trivial task needs a structural thinking step before execution. "Drafter" reads naturally for writing, tax prep, research, policy — sketches a draft approach, same shape as a design. |

That's it. Two roles.

### Why not more

- **Execution role** (implementer / preparer / writer / builder) is inherently domain-specific. Base cannot name it honestly. A mode always provides one.
- **Reviewer of the draft** (design-reviewer) — drop from base. A planner on a non-code PRD who wants extra rigor can call the drafter twice (draft, then a second drafter pass to critique) or add a mode-specific reviewer. Propose-and-check is valuable but not required for base to function; it can be added as a separate base role in a later PRD if demand appears.
- **Spec reviewer** — drop from base. PRD authors on non-code domains will be the same humans; the `/refine` skill already covers spec quality outside the pipeline.
- **Validator / qa** — drop from base. Validation shape is domain-specific; a mode provides it when useful. The drafter's verification sketch plus the execution role's self-check covers the base case.
- **Explorer** — drop from base. Investigation shape is domain-specific. Modes provide when useful.

Two is the true minimum. If the minimum is wrong, a later PRD adds one role. That's cheaper than removing four speculative roles.

### Name rationale

- `planner` — unchanged, already neutral.
- `drafter` — neutral across writing (draft an essay outline), tax (draft a return strategy), research (draft a literature map), policy (draft a position). Avoids "designer" (too close to product/visual design connotation and borderline code-flavored), "architect" (the existing code-mode file), "author" (conflates with PRD author role noted in seed.md), "planner" (already taken).

## 2. Flat perspectives dir + MODE.md

### Directory layout after this task

```
framework/
├── perspectives/                    # flat, all role files together
│   ├── planner.md                   # unchanged
│   ├── drafter.md                   # NEW (base)
│   ├── architect.md                 # unchanged — code-mode role
│   ├── qa-engineer.md               # unchanged — code-mode role
│   ├── design-reviewer.md           # unchanged — code-mode role
│   ├── spec-reviewer.md             # unchanged — code-mode role
│   ├── implementer.md               # unchanged — code-mode role
│   ├── code-cleaner.md              # unchanged — code-mode role
│   ├── code-reviewer.md             # unchanged — code-mode role
│   └── explorer.md                  # unchanged — code-mode role
├── modes/                           # created in task 002 (NOT this task)
│   └── code/
│       └── MODE.md                  # task 002 writes
├── seed.md
├── ralph.md
└── processes/
    └── prd.md
```

Files don't move. Code-mode perspectives keep their current filenames forever. MODE.md is the only new artifact the mode system needs, and task 002 creates it.

### The layering mechanism (one sentence)

Base `prd.md` gets this sentence near the top:

> If the PRD declares a `mode` field, also read `.ralph/modes/<mode>/MODE.md` — it layers mode-specific process content and names the perspective files this mode uses.

That's the whole mechanism. No config, no registry, no loader.

### How a planner knows what roles exist

- Base roles: enumerated by name in `planner.md` (see §3). Two names: `planner`, `drafter`.
- Mode roles: enumerated by name in the active mode's `MODE.md` (task 002 writes that list for `code`). The planner reads `MODE.md` when a mode is active and learns which filenames in `perspectives/` the mode uses.
- A worker resolves a role by reading `.ralph/perspectives/<role>.md`. Flat dir → one lookup path.

No directory scanning. Both sides (base and mode) declare their roles explicitly.

## 3. Base planner's role list

Replace lines 14-16 of `framework/perspectives/planner.md` with:

> The base framework provides two roles:
> - **planner** — this role; composes pipelines.
> - **drafter** — proposes an approach and sketches verification before execution.
>
> The active mode (if the PRD declares one) adds more roles — at minimum an execution role, and often mode-specific reviewers, validators, or investigators. The mode's `MODE.md` names them and may suggest pipeline patterns that have worked for that kind of work. Read the mode file when a mode is active; read a perspective file before committing a role to a pipeline.
>
> If no mode is active, compose from first principles with the two base roles and whatever the task's risk and shape demand.

Keep the rest of `planner.md` (How You Think / What You Produce / What You Avoid) as-is, except remove line 22's hard-coded "exploration/investigation role the active mode provides" phrasing if it reads awkward after the update — leave it if it still reads fine. Implementer judges.

## 4. aa7a43c rollback list

Every change below restores pre-`aa7a43c` wording. Rationale: the phrase uses a domain-specific word as an example or punchy concrete noun within a claim that is itself general. Keep the concrete noun; the claim remains universal.

### `framework/seed.md`

| Location | Current (post-aa7a43c)                                                                         | Restore to (pre-aa7a43c)                                                                       |
| -------- | ---------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Line 10  | `Verify the change works (whatever "works" means for this artifact)`                           | `Verify the change works (run tests, check behavior)`                                          |
| Line 12  | `would this survive a careful second reading by someone who doesn't know what I was trying to do?` | `would this survive a code review by someone who doesn't know what I was trying to do?`       |
| Line 14  | `## Recording Changes`                                                                         | `## Commit Discipline`                                                                         |
| Line 16  | `One logical change per recorded step. Explain why, not just what. A trail that can be followed backward is a trail that can be debugged.` | `Atomic commits — one logical change each. Explain why, not just what. A history that can be bisected is a history that can be debugged.` |
| Line 20  | `Don't form opinions about material you haven't read. When analyzing a problem, read the relevant material first. Cite sources precisely when discussing existing work. Understand not just the piece you're changing, but how it connects to the rest of the system — both structurally (how it fits in the whole) and in terms of the intent it serves (what the user is trying to accomplish end-to-end). A change that works in isolation but breaks the whole is worse than no change.` | `Don't form opinions about code you haven't read. When analyzing a problem, read the relevant code first. Cite specific file:line when discussing existing code. Understand not just the code you're changing, but how it connects to the rest of the system — both technically (how it fits in the codebase) and in terms of the feature or intent it serves (what the user is trying to accomplish end-to-end). A change that works in isolation but breaks the whole is worse than no change.` |
| Line 22  | `You don't need to read everything before making a change.`                                     | `You don't need to read every file in the project before making a change.`                     |
| Line 32  | `Don't add features, polish surrounding material, or make "improvements" beyond the task. A correction doesn't need the surrounding work cleaned up. A simple addition doesn't need extra configurability.` | `Don't add features, refactor surrounding code, add docstrings to unchanged code, or make "improvements" beyond the task. A bug fix doesn't need the surrounding code cleaned up. A simple feature doesn't need extra configurability.` |
| Line 40  | `Three similar pieces are better than a premature abstraction.`                                 | `Three similar lines of code is better than a premature abstraction.`                          |
| Line 69  | `Actively seek the strongest possible verification — produce the artifact, exercise it, prove it works.` | `Actively seek the strongest possible verification — build the thing, run the thing, prove it works.` |
| Line 71  | `If verification machinery is broken, fixing it IS part of verification. If a prerequisite is missing, finding and integrating it IS part of verification.` | `If a test framework isn't functioning, fixing it IS part of verification. If a dependency is missing, finding and integrating it IS part of verification.` |

The Respect Role Boundaries section (lines 50-59) was NOT changed by aa7a43c (grep confirms). It still reads "Architect" / "Implementer". **Leave as-is.** The prose treats "Architect" and "Implementer" as abstract role nouns, not filename references. A non-code PRD reader handles this fine — "architect" is broadly legible. Rewording would itself over-generalize.

The "AGENTS.md paragraph" was removed from seed.md in aa7a43c — that was a genuine move (AGENTS.md is a code artifact). Goes in `modes/code/MODE.md`. Do not restore to base.

### `framework/ralph.md`

| Location | Current (post-aa7a43c)                                                                         | Restore to (pre-aa7a43c)                                                                       |
| -------- | ---------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Line 33  | `**Be honest about verification.** Surface-level checks ≠ working artifact. Say what's really verified.` | `**Be honest about test coverage.** Mocked unit tests ≠ working software. Say what's really tested.` |

The Roles section (lines 11-13) was legitimately generalized — the old version hard-coded eight role names and is now mode-dependent. That's a true move, not a paraphrase. Keep current.

### `framework/processes/prd.md`

| Location    | Current (post-aa7a43c)                                                                         | Restore to (pre-aa7a43c)                                                                       |
| ----------- | ---------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Line 59     | `what boundaries need checking, what would give confidence this works. Does not specify exact checks — that's the implementer's job.` | `what systems and boundaries need testing, what would give confidence this works. Does not specify exact test cases — that's the implementer's job.` |
| Lines 61-63 | Neutralized "Implementer (or whatever...)" + "Validator" paragraph | Original TDD Implementer paragraph + original "QA Engineer" heading + wording (see below). Move the TDD specificity to `code/MODE.md`; base keeps a concrete-but-not-TDD phrasing. |
| Line 63     | `"looks right" and "actually works"`                                                           | `"tests pass" and "it actually works"` — but this is the code-mode sharpening; base keeps its current general phrasing. **Don't restore.** |
| Line 65     | `The architect's design notes (including verification thinking) inform the implementer's approach. The implementer's verification work is the concrete realization...` | `The architect's design notes (including verification thinking) inform the implementer's test design. The implementer's tests are the concrete realization...` |
| Line 101    | `Do the checks exercise real behavior, or just go through the motions? Surface-level verification proves the artifact exists, not that it works.` | `Are the tests testing real behavior, or just mocking everything? Unit tests with fully mocked dependencies prove the code compiles, not that it works.` |
| Line 103    | `Can the human actually exercise what was produced? What steps, what prerequisites (required inputs, credentials, services)?` | `Can the human actually run and test what was built? What commands, what prerequisites (API keys, data, services)?` |
| Line 110    | `**How to exercise it** — Exact steps. Include prerequisites (required inputs, credentials, services).` | `**How to test it** — Exact commands, URLs, or steps. Include prerequisites (e.g., "requires ANTHROPIC_API_KEY").` |
| Line 111    | `**Known gaps** — What ISN'T verified, what might not work, what requires real-world inputs to validate.` | `**Known gaps** — What ISN'T tested, what might not work, what requires real API keys to validate.` |
| Line 112    | `**Confidence level** — "Works end-to-end" vs. "passes in isolation but never run against real inputs" vs. "scaffolding only."` | `**Confidence level** — "Works end-to-end" vs. "unit tests pass but never run against real APIs" vs. "scaffolding only."` |

The Green Builds and Code Cleaning sections were removed from `prd.md` in aa7a43c. Both are genuinely code-specific. **Do not restore to base.** Goes in `modes/code/MODE.md`.

The "QA review" phrasing on line 57 referring to `qa-engineer` — keep it as a code-role reference. In base-only mode, there is no qa-engineer, but the sentence is advisory ("should include"), not normative. Task 002 may move this line into `MODE.md` for clean separation.

### Summary rollback principle

Pre-aa7a43c wording used concrete code vocabulary (`tests`, `code review`, `refactor`, `file:line`, `API keys`, `ANTHROPIC_API_KEY`, `atomic commits`, `bisected`) as *examples within universal claims*. Post-aa7a43c paraphrased these to generic nouns (`material`, `second reading`, `polish`, `sources`, `inputs`, `recorded step`, `followed backward`), weakening prose for no real neutrality gain — the claims were already general. Restore the punch.

Where the claim itself depends on a domain (Green Builds, Code Cleaning, TDD, AGENTS.md, pipeline patterns), the whole claim moves to `MODE.md`. Base keeps general claims with punchy concrete examples.

Ralph is self-hosting and runs almost exclusively on code. Base prose carrying code-flavored examples is legitimate — these are the *examples*, not the claims. A non-code planner reading seed.md understands "code review" as an instance of careful reading, "tests" as an instance of behavior verification, "atomic commits" as an instance of recording a change. The generic nouns help nobody and lose force.

## 5. Manifest for task 002 — content blocks for `framework/modes/code/MODE.md`

Task 002's implementer assembles `modes/code/MODE.md` from these sources. One file.

### 5.1 Role list (mode header)

Names the perspective files this mode uses. Written fresh in task 002. Based on current `framework/perspectives/`:

- `architect` — system analysis, approach design, may split tasks.
- `implementer` — writes code, practices TDD, commits.
- `code-cleaner` — applies fixes directly in one pass, no feedback loop. NOT a validator.
- `code-reviewer` — evaluates code for quality.
- `qa-engineer` — validates from the end-user's perspective. CAN kick back to implementer for another pass. NOT a code-cleaner.
- `design-reviewer` — catches structural design problems before commitment.
- `spec-reviewer` — catches unclear task definitions before work starts.
- `explorer` — maps the codebase before modification.

The `code-cleaner ≠ qa-engineer` distinction must be explicit in MODE.md:
> **code-cleaner** executes fixes directly in one pass, no rounds, no kickback. **qa-engineer** validates from the end-user's perspective and may mark the task for another implementer pass. They are distinct roles; do not collapse.

### 5.2 Content blocks to include in MODE.md

| Block                     | Source                                                          | Notes                                                                        |
| ------------------------- | --------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| Green Builds              | Pre-aa7a43c `framework/processes/prd.md`                        | Quote verbatim; already extracted in v2 design.                              |
| Code Cleaning             | Pre-aa7a43c `framework/processes/prd.md`                        | Quote verbatim.                                                              |
| TDD Verification sharpening | Pre-aa7a43c `framework/processes/prd.md` Verification Cascade  | "Implementer — Practices TDD. Writes tests that verify outcomes before writing implementation code." And: the "tests pass" vs "it actually works" phrasing for the QA Engineer gap. |
| Atomic commits sharpening | Pre-aa7a43c `framework/seed.md` Commit Discipline header       | Base restores "Commit Discipline" + "atomic commits" + "bisected" in §4. MODE.md doesn't need to duplicate; may add a one-line sharpening if the mode has additional commit guidance. Otherwise skip. |
| AGENTS.md paragraph       | Pre-aa7a43c `framework/seed.md` Shared Context section          | `AGENTS.md files in code directories are short orientation (2-5 lines)...` — quote verbatim. |
| Code-mode pipeline patterns | Pre-aa7a43c `framework/perspectives/planner.md` lines 22-28    | `Standard feature/bug fix: architect → implementer → code-cleaner` etc. Quote the pattern list. |
| build-cycle.md contents   | `framework/processes/build-cycle.md`                            | Fold entire file into MODE.md. Content is code-flavored ("writes code, writes tests, runs tests"). Do not keep as a separate file after task 002. |

### 5.3 Pointer sentence in base `prd.md`

Task 001 implementer adds (see §6 below):
> If the PRD declares a `mode` field, also read `.ralph/modes/<mode>/MODE.md` — it layers mode-specific process content and names the perspective files this mode uses.

Task 002 does NOT re-edit this sentence.

### 5.4 Template `prd.json` change

Task 002 adds `mode` field to `framework/templates/prd.json`. Not task 001's concern.

## 6. Implementer scope for this task

### Create

- `framework/perspectives/drafter.md` — new file. Covers: structural thinking before execution, making tradeoffs explicit, sketching how the work will be verified, knowing when to split a task vs proceed. Read `architect.md` for the shape (it's the existing code-flavored analog) but write freshly in neutral voice — no code vocabulary (`tests`, `compile`, `build`, `TDD`, `codebase`). Domain-neutral examples (an outline, a strategy memo, a research plan, a design sketch) are welcome but optional — the prose should read naturally for any of them without naming any of them. Start with `Read .ralph/seed.md first — it contains principles that apply to all roles.` convention.

### Edit

- `framework/seed.md` — restore lines per §4 (Own the Quality Loop, Commit Discipline, Read Before Judging, Stay in Scope, Keep It Simple, Verification Rigor). The Respect Role Boundaries section is NOT edited.
- `framework/ralph.md` — restore line 33 per §4.
- `framework/processes/prd.md` — restore lines per §4. **Also add** the one-sentence mode pointer at the top (immediately after the "Any agent working on a PRD task follows these rules." line).
- `framework/perspectives/planner.md` — replace lines 14-16 with the expanded role-list text from §3.

### Do NOT touch

- Any existing perspective file in `framework/perspectives/` **other than `planner.md`**. In particular: `architect.md`, `qa-engineer.md`, `design-reviewer.md`, `spec-reviewer.md`, `implementer.md`, `code-cleaner.md`, `code-reviewer.md`, `explorer.md` are byte-identical after this task.
- `framework/processes/build-cycle.md`. Task 002 folds it into `modes/code/MODE.md`.
- `framework/modes/`. Task 002 creates it.
- `framework/templates/prd.json`. Task 002 edits it.
- `framework/template.claude.settings.json`. Task 007.
- `.ralph/` — NEVER. Source is in `framework/`.

### Verification for the implementer's step

1. `git diff aa7a43c -- framework/perspectives/architect.md framework/perspectives/qa-engineer.md framework/perspectives/design-reviewer.md framework/perspectives/spec-reviewer.md framework/perspectives/implementer.md framework/perspectives/code-cleaner.md framework/perspectives/code-reviewer.md framework/perspectives/explorer.md framework/processes/build-cycle.md` is empty.
2. `framework/perspectives/drafter.md` exists and, on a careful read, works for a writing, tax-prep, or research PRD.
3. The rollback diffs from §4 applied cleanly; the listed pre-aa7a43c phrases now appear in base prose.
4. `framework/processes/prd.md` contains the one-sentence mode pointer.
5. `framework/perspectives/planner.md` enumerates `planner` and `drafter` by name and mentions `MODE.md`.

That's the whole task.
