# Task 002 — Design: Create the `code` mode

Task 001 set the shape: flat `framework/perspectives/`, base prose lean-but-not-hollow, a one-sentence mode pointer in `framework/processes/prd.md`, and a §5 manifest of content blocks destined for MODE.md. This task lands the mode itself — one new file (`framework/modes/code/MODE.md`), one deletion (`framework/processes/build-cycle.md`), one template field (`mode` on `framework/templates/prd.json`), and enough wire-up prose so the planner and workers actually read MODE.md when a mode is active.

The design is deliberately mechanical. Most decisions were made in task 001; this task is mostly assembly.

## 1. MODE.md structure

### 1.1 Layout (headers, ordering, rationale)

One file, two jobs (registry + process addendum), clear section headers so each job is easy to find. The registry goes first — that's what a planner reads first to compose a pipeline, and a short registry up top is cheap to scan when the reader's question is "which roles does this mode offer?" Process content comes after, because it only matters once a worker is executing and usually after they've read base `seed.md` and base `prd.md`.

Headers, in order:

1. `# Code Mode` — title.
2. Lead sentence naming the mode's domain (software engineering) and what the file layers.
3. `## Perspectives` — the role registry (§3 below). Unambiguous bulleted list: filename + one-line summary.
4. `## Pipeline Patterns` — common pipelines a planner can reach for. Prose + bulleted list, from the old `planner.md` patterns block.
5. `## Seed Addendum` — code-specific principles that layer on top of base `seed.md`. Currently one sub-section: `### AGENTS.md`.
6. `## PRD Process Addendum` — code-specific content that layers on top of base `processes/prd.md`. Sub-sections:
   - `### Green Builds`
   - `### Code Cleaning`
   - `### TDD in the Verification Cascade`
   - `### code-cleaner vs qa-engineer` (the explicit distinction that task 001 §5 flagged)
7. `## Build Cycle` — the entire content of `framework/processes/build-cycle.md`, folded in.

That ordering lets a planner stop reading after §3 (registry) or §4 (patterns) and still get value. A worker picks up from §5 onward.

### 1.2 Full MODE.md content (copy/adapt target for the implementer)

The text below is the full MODE.md the implementer should produce. Every block is sourced from task 001's §5 manifest, the `extracted-for-code-mode.md` manifest, or pre-aa7a43c originals. The implementer may make minor wording adjustments for connective prose between sections, but should not re-derive substantive content.

````markdown
# Code Mode

The code mode layers software-engineering-specific process and perspectives on top of the base framework. Ralph reads this file when a PRD declares `"mode": "code"`.

## Perspectives

The code mode uses these perspective files from `.ralph/perspectives/` (filenames, one-line role summaries):

- **architect** — analyzes systems, proposes approaches, may split tasks.
- **implementer** — writes code, practices TDD, commits.
- **code-cleaner** — applies fixes directly in one pass, no feedback loop.
- **code-reviewer** — evaluates code for quality and correctness.
- **qa-engineer** — validates from the end-user's perspective; can kick work back to implementer for another pass.
- **design-reviewer** — catches structural design problems before commitment.
- **spec-reviewer** — catches unclear task definitions before work starts.
- **explorer** — maps the codebase before modification.

`code-cleaner` and `qa-engineer` are distinct roles. **code-cleaner** executes fixes directly — one pass, no rounds, no kickback. **qa-engineer** validates from the user's perspective and may mark the task for another implementer pass. Do not collapse them.

The base roles (`planner`, `drafter`) are still available; the code mode does not exclude them. In practice code pipelines rarely use `drafter` — `architect` covers structural thinking for engineering work.

## Pipeline Patterns

Common patterns a planner can reach for:

- Standard feature / bug fix: `architect → implementer → code-cleaner`
- Trivial change: `implementer → code-cleaner`
- Complex system change: `explorer → architect → implementer → code-cleaner`
- High-level or user-facing: `architect → implementer → qa-engineer → code-cleaner`
- Investigation / research: `explorer` or `architect` alone

These are patterns, not a menu. Compose what fits the task.

## Seed Addendum

These principles layer on top of base `seed.md` for code work.

### AGENTS.md

AGENTS.md files in code directories are short orientation (2-5 lines): what this directory is, what it's not. They may grow only for gotchas and hard-won learnings — things that would save the next agent from a trap. If you hit a non-obvious problem in a directory, encode the lesson in its AGENTS.md. Don't pre-fill them with architecture or file listings.

## PRD Process Addendum

These rules layer on top of base `processes/prd.md` for code PRDs.

### Green Builds

Every task that changes code must leave all tests passing. Red builds are broken windows — they multiply quickly. Don't assume a failing test isn't yours. If tests fail when you're done, fix them before marking your step complete.

### Code Cleaning

The code-cleaner applies fixes directly — it doesn't kick back to the implementer. It commits corrections for correctness issues, simplifies unnecessary complexity, and aligns with project patterns. One pass, no rounds.

### TDD in the Verification Cascade

The base Verification Cascade describes a generic execution role that "operationalizes the architect's verification strategy." For code, sharpen that to TDD:

> **Implementer** — Practices TDD. Writes tests that verify outcomes before writing implementation code.

And the QA Engineer gap: where base says "looks right" vs "actually works," code reads that as "tests pass" vs "it actually works." Mocked unit tests ≠ working software.

### code-cleaner vs qa-engineer

See the Perspectives section above. Both appear in code pipelines; they do different work. Do not substitute one for the other.

## Build Cycle

The standard process for completing a task. Used by Ralph when orchestrating, or by a human directing agents manually.

### The Cycle

```
[spec review] → architect → implement → review → (fix → review)* → done
```

0. **Spec review** (optional gate): Before the first task in a new PRD, review all task specs for clarity, scope, and specification-creativity balance. This is a gate — if specs need revision, stop and revise before proceeding. Can be skipped for well-refined PRDs.

1. **Architect** analyzes the task. Produces an approach (what to change, why, constraints). Does NOT produce step-by-step instructions — the implementer is skilled.

2. **Implementer** executes the approach. Writes code, writes tests, runs tests, commits when passing.

3. **Reviewer** checks the implementation. Stage 1: correctness (did they build the right thing?). Stage 2: quality (is it clean and tested?).

4. If the reviewer finds issues, the **implementer** fixes them with the review feedback as context. Then back to review. Max 3 rounds.

5. If still unresolved after 3 rounds, the task is **blocked**. Record the issue. A human or architect decides what to do next.

### When to Skip Steps

- **Trivial tasks** (rename, config change, one-line fix): skip architect, go straight to implement + review.
- **Pure investigation** (research, analysis): only architect. No implementation.
- **Already designed**: if the task has an approved design document, skip architect.

Use judgment. The cycle is a default, not a mandate.

### Parallel Tasks

If tasks are independent (no shared files, no dependency relationship), they can run through the cycle in parallel. Ralph dispatches separate subagent chains for each.

### Redo

When a human marks a task for redo with feedback:
1. The feedback becomes additional context for the architect
2. Re-run the cycle from architect (or from implement if the approach was fine)
3. Check dependent tasks — they may need to adapt
````

### 1.3 What was NOT included and why

- **Atomic commits sharpening**: base already has the punchy "atomic commits / bisected" phrasing restored in task 001. No duplicate needed. (Manifest §5.2 flagged this as skippable.)
- **A separate "Seed" section for TDD principles**: TDD already lives in `framework/perspectives/implementer.md`. Pulling it into MODE.md as a separate top-level principle duplicates content. The Verification Cascade sharpening in §5 (PRD Process Addendum) is enough to flag "this mode is TDD-shaped" for planners and reviewers who never open `implementer.md`.

## 2. Who reads MODE.md

### 2.1 Decision

**Every agent working on a PRD that declares a mode reads MODE.md.** Mechanism: they already read base `processes/prd.md` (standard PRD-work intake), and base `prd.md` now carries the one-sentence mode pointer (landed in task 001). Any agent that follows the pointer reads MODE.md. No per-role tailoring.

### 2.2 Rationale

The planner must read it — needs the registry to compose pipelines, needs the patterns to propose them efficiently.

Individual workers (implementer, code-cleaner, code-reviewer, qa-engineer) benefit from the Green Builds, Code Cleaning, TDD, and Build Cycle sections. These *are* mode process rules; a worker who skipped MODE.md would miss the Red Build prohibition and the one-pass code-cleaner discipline. Cross-referencing from base perspective files is the alternative — but base perspective files (architect, planner, drafter, etc.) should stay mode-agnostic, and code-mode perspective files (implementer, code-cleaner, etc.) already assume their mode context by their content. The cleanest path is: everyone reading `prd.md` also reads `MODE.md` when a mode is active.

The simplest path (workers inherit via `prd.md`'s pointer) wins. No bespoke wire-up per role, no fear of drift between perspective files and MODE.md, and the cost to workers is small — MODE.md is a few hundred lines, read once per task.

### 2.3 Consequence for base `prd.md`

No change to `prd.md` in this task — the pointer already says "also read `.ralph/modes/<mode>/MODE.md`" and already triggers for any agent reading `prd.md`. Confirmed sufficient.

## 3. Perspective registry format

The planner needs a deterministic read path. It's given:

- Filename (so it can `Read .ralph/perspectives/<name>.md` when deciding whether to include that role).
- One-line role summary (so it can decide which roles to include without opening every file speculatively).

Format: a bulleted list under the `## Perspectives` heading, with each bullet in the form `**<filename-without-md>** — <one-line summary>.`

Exact form — copy this into MODE.md verbatim (see §1.2 for the full block):

```
## Perspectives

The code mode uses these perspective files from `.ralph/perspectives/` (filenames, one-line role summaries):

- **architect** — analyzes systems, proposes approaches, may split tasks.
- **implementer** — writes code, practices TDD, commits.
- **code-cleaner** — applies fixes directly in one pass, no feedback loop.
- **code-reviewer** — evaluates code for quality and correctness.
- **qa-engineer** — validates from the end-user's perspective; can kick work back to implementer for another pass.
- **design-reviewer** — catches structural design problems before commitment.
- **spec-reviewer** — catches unclear task definitions before work starts.
- **explorer** — maps the codebase before modification.
```

The list is unambiguous because:

- Each bullet's boldface token is literally the filename stem — `architect` means `.ralph/perspectives/architect.md`. No separate "name vs filename" mapping needed.
- The one-liner is short enough that the planner can treat it as the role's identity card; they open the full perspective file only when they've decided a role is a candidate.
- Role distinctions that historically confused agents (`code-cleaner` vs `qa-engineer`) have an explicit disambiguation paragraph right after the list.

No heading-within-heading, no table, no JSON — the planner is a language model; a bulleted list with a known heading is the shortest read path that leaves no ambiguity.

## 4. PRD template update

Add a `mode` field to `framework/templates/prd.json`, top-level, sibling of `name`/`description`/`signoff`.

- **Type**: string.
- **Semantics**: names a mode directory under `.ralph/modes/`. Empty string or omitted means "no mode — run base-only."
- **Default in the template**: `"code"`.

Why `"code"` and not empty:

1. It accurately represents the current population. Virtually every real PRD this repo runs is a code PRD. Leaving it empty forces every author to type the same value and punishes the default case.
2. It makes the template self-documenting: a new PRD author sees `mode: "code"` and understands there are modes, that `code` is one, and that they can change it.
3. It preserves backwards-behavior: any PRD copied from the template continues to run with the full code-mode pipeline patterns and process addendum, matching pre-PRD-006 behavior.
4. The no-mode path is still trivially reachable — a non-code PRD author sets `"mode": ""` or removes the field.

Template file after this task:

```json
{
  "name": "",
  "description": "",
  "mode": "code",
  "signoff": "full",
  "tasks": [
    {
      "id": "001",
      "description": "",
      "outcome": "",
      "verification": "",
      "dependencies": [],
      "status": "pending",
      "pipeline": []
    }
  ]
}
```

`mode` sits between `description` and `signoff` — grouped with PRD-level metadata, before the execution-control field.

## 5. Loading wire-up

The base `prd.md` pointer landed in task 001. It says:

> If the PRD declares a `mode` field, also read `.ralph/modes/<mode>/MODE.md` — it layers mode-specific process content and names the perspective files this mode uses.

That one sentence does the entire job for any agent that already reads `prd.md` when picking up PRD work — which is every role (`seed.md` line 5 directs perspective readers to `prd.md` when on a PRD task, and `ralph.md` line 8 directs Ralph itself to `prd.md` on startup).

### 5.1 Does planner need its own pointer?

**No.** The planner already reads `prd.md` (it is the first pipeline step on every task), and the planner role file (`planner.md` lines 14-20, landed in task 001) already says:

> The mode's `MODE.md` names them and may suggest pipeline patterns that have worked for that kind of work. Read the mode file when a mode is active; read a perspective file before committing a role to a pipeline.

That's a second, role-specific mention — redundant with `prd.md`'s pointer but beneficial: a planner skimming only `planner.md` still lands on MODE.md. Task 002 does not need to add a third pointer.

### 5.2 Do workers need a pointer in their perspective files?

**No.** Workers read `prd.md` when on a PRD task (base `seed.md` line 5). The pointer in `prd.md` catches them. Adding per-role pointers would create drift: every new mode perspective file would need updating, and the point of the pointer-in-prd.md design is exactly to avoid that.

### 5.3 Summary of wire-up changes in this task

None beyond the MODE.md file itself and the PRD template field. The pointer already exists; the planner role file already directs at MODE.md; everything else inherits via `prd.md`. The mechanism is already in place — this task just makes `modes/code/MODE.md` exist so the pointer resolves to something.

## 6. No-mode path audit

A PRD without a `mode` field (or with `"mode": ""`) runs base-only. Full trace:

1. Ralph reads the PRD, sees no `mode` (or empty).
2. Ralph dispatches the planner. Planner reads `seed.md` → `planner.md` → `prd.md`.
3. In `prd.md`, the mode pointer sentence is conditional: *"If the PRD declares a `mode` field, also read..."* — condition false, skip.
4. Planner composes the pipeline from the base roles enumerated in `planner.md`: `planner`, `drafter`. No `architect`, `implementer`, etc. because those are mode-specific per the `planner.md` text.
5. The planner produces a `drafter` step (most non-trivial tasks need it); trivial tasks may skip straight to... nothing. Base has no execution role. That's a real limitation and a known one — base is minimum viable, and a PRD with no mode and no drafter has no executor. That's fine; modes exist precisely to provide the executor.
6. The drafter runs, reads `seed.md` → `drafter.md` → `prd.md`. Mode pointer again false, skipped. Drafter does its work, marks its step complete.
7. Pipeline has no further steps. Task moves to the next stage / human review.

Files checked for mode assumptions:

- `framework/seed.md` — no mention of `mode`. No assumption.
- `framework/ralph.md` — line 12 says "plus any the active mode adds" — gracefully handles the no-mode case (no mode → no additions → base only).
- `framework/processes/prd.md` — mode pointer is explicitly conditional. Line 63's "Implementer (or whatever the active mode calls the execution role)" is advisory, not normative.
- `framework/perspectives/planner.md` — lines 14-20 explicitly cover the no-mode case: *"If no mode is active, compose from first principles with the two base roles..."*.
- `framework/perspectives/drafter.md` — does not reference mode.

Nothing assumes a mode is set. Base-only runs cleanly.

## 7. In-flight PRD treatment

The PRD we're currently in (006) has no `mode` field today. After task 002 lands, its remaining tasks (004, 005, 006, 007, 008) keep running. Option analysis:

- **Option A: add `"mode": "code"` to PRD 006.** Runs tasks 004-008 under the code-mode pipeline patterns, including MODE.md's TDD / Green Builds / Code Cleaning rules. Natural fit — these tasks ARE code work (rename, install flow, docs cleanup, non-blocking question mechanism).
- **Option B: leave PRD 006 without a mode.** Runs tasks 004-008 base-only. Base has no `implementer`, `code-cleaner`, `architect`, etc. in its planner enumeration. But — the existing pipelines in PRD 006 tasks 004-008 already list `architect`, `implementer`, `code-cleaner` as pipeline steps (see the PRD JSON). Those roles still exist as files in `framework/perspectives/`. The planner step is already complete on every one of those tasks, so no further planner call will re-derive the pipeline. Workers simply look up `perspectives/<role>.md` and work. The no-mode path doesn't block role file reads — it only constrains what the planner enumerates when composing new pipelines.

**Recommendation: Option A.** Add `"mode": "code"` to PRD 006. Rationale:

1. It makes the PRD's intent explicit and matches the real nature of the work.
2. It means in-flight workers reading `prd.md` will follow the pointer to MODE.md and pick up Green Builds, Code Cleaning, and the code-cleaner-vs-qa-engineer clarification — which they benefit from for tasks 005-008.
3. It validates the mode mechanism end-to-end in this repo from the moment task 002 lands, rather than deferring the first real use to a future PRD.
4. It costs nothing (one-line JSON edit).

The implementer should add `"mode": "code"` to `ralph-context/prds/006-modes-and-multisession.json` as part of this task (alongside updating the task 002 pipeline status at commit time). This is a one-line edit; not a framework change.

Option B is also safe — worker lookups do not depend on mode. A future in-flight non-code PRD that lacks a `mode` field would likewise still run. But for 006, explicit > implicit.

### 7.1 What about other ongoing PRDs?

The other PRDs currently in the repo (`ralph-context/prds/`) should be surveyed by the implementer — any PRD with `status: "in_progress"` and without a `mode` field should either get `"mode": "code"` added or be confirmed to not need it. In this repo today only 006 is in-flight on this branch; others are complete or on different branches. Implementer scope §8.2 captures the sweep.

## 8. Implementer scope

### 8.1 Create

- `framework/modes/code/MODE.md` — full content per §1.2 above. Copy the fenced block verbatim, trimming the outer fence. Quote the internal fenced block (the build-cycle diagram) as-is.

### 8.2 Edit

- `framework/templates/prd.json` — add `"mode": "code"` between `description` and `signoff` per §4.
- `ralph-context/prds/006-modes-and-multisession.json` — add `"mode": "code"` at the top level, between `description` and `signoff`. Per §7 recommendation.

### 8.3 Delete

- `framework/processes/build-cycle.md` — content folded into MODE.md §7. Before deleting, confirm no *framework* file references it: `grep -rn "build-cycle" framework/` and `grep -rn "build-cycle" .claude/skills/`. Task-context/design files that mention `build-cycle.md` historically are left alone (they are immutable task history). `docs/structure.md:26` shows `build-cycle.md` inside an ASCII directory listing of `framework/processes/` — update that listing to remove the line. No other live doc references it (confirmed: task 001 architect grepped; only historical task-context files mention it).

### 8.4 Do NOT touch

- Any file in `framework/perspectives/` — all ten files stay byte-identical.
- `framework/seed.md`, `framework/ralph.md`, `framework/processes/prd.md` — task 001 already landed the edits these files needed.
- `.ralph/` — installed copy; never edit directly. Source is `framework/`.
- `framework/template.claude.settings.json` — task 007.
- Any task-context file in `ralph-context/tasks/` — immutable history.

### 8.5 Commit message conventions

Suggested commits (implementer judgment on granularity):

1. `Task 002: create framework/modes/code/MODE.md` — the new file.
2. `Task 002: add mode field to PRD template` — the template edit + optionally the PRD 006 self-update.
3. `Task 002: fold build-cycle.md into MODE.md` — the deletion + docs/structure.md update.

Or one squashed commit if the implementer prefers atomicity-per-task over atomicity-per-concern. Either is fine.

## 9. Verification strategy

The implementer proves the design works with four checks:

### 9.1 Content preservation

Every block listed in task 001's §5 manifest and §1.2 of this design is present in the final `MODE.md`. Checklist:

- [ ] Green Builds — verbatim from pre-aa7a43c `prd.md`.
- [ ] Code Cleaning — verbatim from pre-aa7a43c `prd.md`.
- [ ] TDD sharpening of Implementer + QA Engineer — present in `### TDD in the Verification Cascade`.
- [ ] AGENTS.md paragraph — verbatim from pre-aa7a43c `seed.md`.
- [ ] Pipeline patterns — all five patterns from pre-aa7a43c `planner.md`.
- [ ] code-cleaner ≠ qa-engineer distinction — explicit in `## Perspectives` and `### code-cleaner vs qa-engineer`.
- [ ] `build-cycle.md` — entire content present in `## Build Cycle`.
- [ ] Perspective registry — all eight code-mode perspective files listed.

A manual pass through §1.2 of this design against the produced MODE.md is the quickest proof.

### 9.2 No stale references

```
grep -rn "build-cycle" framework/ .claude/
```

Returns no live matches (task-context and ralph-context/ historical files allowed).

```
grep -rn "build-cycle" docs/
```

Returns nothing — `docs/structure.md` was updated to remove the listing.

### 9.3 Self-hosted end-to-end check

After the implementer's commits and a re-sync of `.ralph/` from `framework/`:

1. Pick any task from PRD 006 with a pending pipeline step (e.g., task 004 or 005, which are `in_progress` with pending steps).
2. Dispatch a subagent for that step.
3. Verify: agent reads `prd.md`, sees the mode pointer, reads `.ralph/modes/code/MODE.md`, and proceeds normally. Check via the agent's output for references to MODE.md content (Green Builds, etc. — not required in output, but behavior should be code-mode flavored).

The test is pass/fail by "does the pipeline still flow." If an agent hits MODE.md and stops, something is wrong. If an agent proceeds and produces work, the mechanism works.

### 9.4 No-mode smoke test (optional, stronger proof)

Create a throwaway PRD with no `mode` field and one task. Run the planner. Expect:

- Planner reads `prd.md`, skips the mode pointer (condition false).
- Planner composes a pipeline using only `planner` + `drafter` (or notes that the task needs a mode's execution role).
- No error, no hang.

Not strictly required for task sign-off — §6's audit is the proof-by-reading. But if the implementer has time, a one-task throwaway PRD is the fastest behavioral confirmation.

### 9.5 PRD 006 continues to flow

After task 002's commits land and `.ralph/` is re-synced, task 004 (or any other in-flight task) can be picked up by an agent without errors. PRD 006 now has `"mode": "code"`; the MODE.md file exists; the pointer resolves; workers read it. No PRD 006 work is stranded.

---

That's the design. The implementer's job is assembly, a small PRD template edit, a one-line PRD 006 self-update, a file deletion, and a docs-listing touch-up. No framework prose changes beyond MODE.md itself.
