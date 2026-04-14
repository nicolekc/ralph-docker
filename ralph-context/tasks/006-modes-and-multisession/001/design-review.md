# Task 001 — Design Review

## Summary

**Fail — fixes needed (implementer redo).** The four files explicitly listed in the architect's design (`seed.md`, `ralph.md`, `perspectives/planner.md`, `processes/prd.md`) are cleanly generalized and the extraction manifest covers their carved content well. But the PRD task description (and the architect's own roster on design.md line 32) named **five** base perspectives that "stay in the base but may need light edits to remove code-flavored language": architect, planner, design-reviewer, spec-reviewer, qa-engineer. The implementer only edited `planner.md`. The other four base perspective files were never read against the code-terminology bar, and three of them (`architect.md`, `qa-engineer.md`, `spec-reviewer.md`) contain explicit code-mode language that breaks the tax-prep read-through. The manifest also has no entry for what gets carved out of these files, so task 002 will not know to pick it up.

The fix is bounded: edit three perspective files, add one section to the manifest. No design rework needed.

## Strengths

- The four in-scope files read cleanly for a non-code domain. Tax-prep, research, writing — all work. The neutral vocabulary (artifact / verification / recording changes) lands well.
- `seed.md` rewrites are tight and preserve voice. "A trail that can be followed backward is a trail that can be debugged" keeps the original aphoristic feel.
- `ralph.md` Roles section collapses cleanly to a one-paragraph principle pointing at base + mode directories — exactly the right shape for the task 002 loader to land on top of.
- `planner.md` Common patterns replacement is well-judged: directs to the active mode without the base needing to know mode internals.
- Manifest entries for the four edited files are precise — source text quoted verbatim, original location named, intent for the code mode explained. Task 002's architect can pick up sections 3, 4, and 5 without re-deriving the boundary.
- The architect's catch on `framework/processes/build-cycle.md` (audit missed it) propagated correctly into manifest §2.
- Self-host caveat is correctly flagged — `.ralph/` is stale, end-to-end verification waits for task 002. Implementer didn't waste time chasing untestable behavior.
- Cross-reference integrity holds. No dangling pointers in the four edited files.

## Issues

### 1. Base perspective files were not edited (HIGH)

The PRD task description states: "Perspectives that are already general (architect, planner, design-reviewer, spec-reviewer, qa-engineer) stay in the base but may need light edits to remove code-flavored language." The architect's design.md echoed this roster on line 32. The implementer only edited `planner.md` and never swept the other four.

Three of those four contain explicit code-mode language that fails the tax-prep read-through:

**`framework/perspectives/architect.md`:**
- Line 10: "Never form opinions about code you haven't read — cite file:line"
- Line 39: "What systems/layers need testing? (unit, integration, e2e?)"
- Line 41: "What would give confidence this actually works vs just compiles?"
- Line 42: "Can the current test infrastructure exercise this code? If not, what's missing? Flag infrastructure gaps explicitly — the implementer cannot practice TDD if there is no way to run tests for the code they are writing."
- Line 44: "Your verification thinking informs the implementer's TDD approach — they turn your strategy into concrete tests. You don't prescribe specific test cases or test frameworks."
- Line 48: "Writing implementation code (pseudocode for tricky algorithms is fine)"

A tax-prep architect reading this is told to think about TDD, test frameworks, and "compiles" vs "works". This is not light leakage — it is the same class of code-mode content the implementer correctly removed from `prd.md`'s Verification Cascade.

**`framework/perspectives/qa-engineer.md`:**
- Line 11: "Run the system as a user would — actual usage paths, not programmatic tests"
- Line 20: "Automated tests prove the code does what the programmer intended. You prove it does what the human intended."
- Line 22: "Programmatic tests follow defined paths — real usage is messier"
- Line 24: "If something feels wrong to use even though tests pass, that's a real finding"
- Line 29: "Re-reviewing code quality — that's the code-cleaner's job"

**`framework/perspectives/spec-reviewer.md`:**
- Line 11: "Each criterion should read like a test assertion"
- Line 15: "Can the result be tested?"
- Line 26: "Code quality is the code reviewer's job"

`design-reviewer.md` is clean — no code-specific terms found.

These three files need the same generalization treatment the four in-scope files received. The "Boundaries" / "What You Avoid" sections that reference `code-cleaner` and `code reviewer` are particularly important to fix because they assume base-layer roles that won't exist outside the code mode.

### 2. Manifest missing perspective-extraction entries (HIGH, blocks task 002)

The extraction manifest has no section covering what gets carved out of `architect.md`, `qa-engineer.md`, and `spec-reviewer.md`. Once those files are generalized (per issue #1), the carved code-mode language needs to live somewhere — a code-mode addendum to each base perspective, or merged into the existing code-mode perspective files. Task 002's implementer needs to know this content was moved out and where to put it. Without manifest entries, this content is at risk of being silently dropped.

The fix is to add a section 6 (or extend section 3) listing each carved block by source file:line, source text, and intended code-mode placement.

### 3. Verification scope was too narrow (MEDIUM)

The implementer's verification.md grep sweep was scoped only to the four edited files. The PRD-stated bar is that the *base layer* (not just those four files) reads naturally for any domain. The grep should have covered all files that remain in the base after this task — i.e., all base perspective files plus seed/ralph/prd. Re-running the grep at the wider scope would have caught issue #1 immediately.

This is a process gap, not just a missed file. Calling it out so the redo iteration uses the right scope.

### 4. Minor: `prd.md:22` "commit the PRD update" (LOW, acceptable)

Verification flagged this as acceptable git-machinery language. I agree — the multi-agent coordination layer needs git, and "commit" here refers to the literal git operation that all modes share. Leave as-is. Noting only so the redo doesn't accidentally over-correct it.

## Recommendation

**Redo at the implementer step.** Specifically:

1. Generalize `framework/perspectives/architect.md`, `qa-engineer.md`, `spec-reviewer.md` using the same vocabulary discipline (artifact / verification / recording) and the same "what survives in the base" judgment that the four in-scope files received. Particular attention to:
   - architect.md's verification section (lines 38-44) — the TDD/test-framework specifics belong in the code mode; the base keeps "what boundaries need checking, what would give confidence."
   - qa-engineer.md's "The Gap You Fill" section — generalize "automated tests" / "programmatic tests" / "code" to the verification-vs-actually-works framing already used in `prd.md`.
   - spec-reviewer.md's Boundaries section — drop the `code reviewer` / `code-cleaner` references; replace with whatever the active mode's quality role is (or just omit, since spec-reviewer's own boundaries are clear enough without naming downstream roles).
2. Add a manifest section covering the content carved from these three files, with source text and intended code-mode placement (likely as code-mode addenda or merges into existing code-mode perspectives).
3. Re-run the grep sweep at the wider base-layer scope (all files that remain in the base after this task, not just the four originally listed).

The four already-edited files do not need re-work. The architect's design and the implementer's manifest mechanics are sound — this is a scope-of-execution fix, not a design-rework fix.
