# Code Mode

The code mode layers software-engineering-specific process and perspectives on top of the base framework. Ralph reads this file when a PRD declares `"mode": "code"`.

## Perspectives

The code mode uses these perspective files from `.orca/perspectives/` (filenames, one-line role summaries):

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
