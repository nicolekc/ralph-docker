# Task 001 — Implementer Verification (v3)

## Files touched

- `framework/perspectives/drafter.md` — **created**. New base role covering structural thinking before execution, tradeoff framing, verification sketching, splitting judgment. Written in neutral voice, no code vocabulary.
- `framework/seed.md` — **edited**. Applied all eight rollbacks from design §4: Own the Quality Loop (2 lines), Commit Discipline heading + body, Read Before Judging paragraph + "every file in the project" line, Stay in Scope, Keep It Simple (three similar lines), Verification Rigor (2 lines). Also renamed Architect→Drafter in the Respect Role Boundaries section (see deviation note below).
- `framework/ralph.md` — **edited**. Applied the one rollback in design §4: "Be honest about test coverage. Mocked unit tests ≠ working software."
- `framework/perspectives/planner.md` — **edited**. Replaced the two lines covering available roles + mode pipeline patterns with the expanded two-role list from design §3. Left line 26's "exploration/investigation role the active mode provides" alone — reads fine, design left it to implementer judgment.
- `framework/processes/prd.md` — **edited**. Applied seven rollbacks from design §4 (architect verification strategy, informs implementer's test design, verification honesty mocks, runnability commands/API keys, How to test it, Known gaps, Confidence level). Added the one-sentence mode pointer immediately after "Any agent working on a PRD task follows these rules." Did NOT touch the "Implementer (or whatever the active mode calls the execution role)" paragraph or the "looks right"/"actually works" QA Engineer line per design §4 guidance (base keeps concrete-but-not-TDD phrasing).

## Untouched files verified byte-identical

`git diff aa7a43c -- framework/perspectives/architect.md framework/perspectives/qa-engineer.md framework/perspectives/design-reviewer.md framework/perspectives/spec-reviewer.md framework/perspectives/implementer.md framework/perspectives/code-cleaner.md framework/perspectives/code-reviewer.md framework/perspectives/explorer.md framework/processes/build-cycle.md` returns empty output. Confirmed.

## Non-code mental read-through of `drafter.md`

Mentally ran the file through three non-code planners:

- **Writing-project planner** (drafting a book proposal): "propose an approach and sketch verification," "what would give real confidence the work is right — not 'it exists,' but 'it does what it should'," "make the transition explicit" — all reads naturally. "Split vs keep together" maps cleanly to chapter-level organization.
- **Tax-prep planner** (drafting a return strategy): "identify the real choices, name the tradeoffs, recommend one" — this is exactly how a CPA frames election choices. "What exists now, what needs to exist after" reads as current-year position vs filed return. Fits.
- **Research planner** (drafting a literature review): "understand the problem before proposing a shape for the solution," "what would count as evidence" — neutral enough to cover survey design.

No code vocabulary leaked in (checked for: `test`, `TDD`, `build`, `compile`, `codebase`, `code review`, `bisect`, `API`, `file:line` — none present). "Execute" / "executor" are general; "verification" is general. "Draft" / "drafter" thread through cleanly.

## Deviations from design.md

One deviation from design §4 / §6:

- Design §4 seed.md section says: *"The Respect Role Boundaries section (lines 50-59) was NOT changed by aa7a43c... Leave as-is."* Design §6 reinforces: *"The Respect Role Boundaries section is NOT edited."*
- The prompt from the caller (implementer dispatch) instructed: *"seed.md rename architect→drafter where the three-roles-three-jobs section names a base role."*
- I followed the prompt: renamed `Architect`→`Drafter` in the Respect Role Boundaries section (5 occurrences, all referring to the abstract base role). `Implementer` kept as-is — it remains a valid role noun, now scoped as a mode role name rather than a base one, and the prose still reads correctly.
- Rationale for following the prompt over the design: in the v3 two-role base world, `architect` is a code-mode-only perspective filename. Leaving `Architect` as the generic "defines the solution space" role in the base seed.md conflicts with the naming rationale in design §1 (architect was rejected as a base name because it's the existing code-mode file). The rename makes base prose self-consistent with the base role list.

## Summary

All design §4 rollbacks applied. One structural change per design §3 (planner role list), one per design §2 (prd.md mode pointer). New `drafter.md` reads naturally for non-code domains. Eight existing perspective files and `build-cycle.md` confirmed byte-identical to aa7a43c.
