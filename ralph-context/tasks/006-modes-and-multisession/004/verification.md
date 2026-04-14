# Task 004 Implementer Verification

## Files touched

- `framework/ralph.md` — added "Questions (when enabled)" section (between "Execution" and "Task Completion Assessment") covering: conditional dispatch-prompt injection gated on PRD `"questions": true`, semantics of the `needs_input` step status (not dispatchable, not counted toward the 3-attempt limit, task cannot complete while any step is `needs_input`), surfacing logic (batch when no dispatchable work, verbatim content, `── Task <id> / <role> ──` header), answer handling (append under `---\n## Answer\n` divider, flip steps to `pending`), and the note that `needs_input` is recognized regardless of flag state.
- `framework/processes/prd.md` — added a "Step Statuses" subsection under "Your Step" (enumerating `pending`, `in_progress`, `complete`, `needs_input` with semantics for the new status) and a new "Questions" section (between "Durable Context" and "Modifying the PRD") covering the `questions` field, the `questions/NNN.md` convention, the `## Answer` divider format, and the "use sparingly" guidance.
- `framework/seed.md` — added a short "Questions (when enabled)" principle after "Autonomy" framing the mechanism as a valve for genuine ambiguity, not a substitute for autonomy.
- `framework/templates/prd.json` — added `"questions": false` at the top level, alongside `"mode"` and `"signoff"`.

## Confirmation the gated default preserves current behavior

With `"questions": false` (or omitted — same effect since the template default is `false`), per `ralph.md` the dispatch prompt does not include the question paragraph. Agents therefore do not learn the capability exists and continue operating on the existing options: best judgment, or `blocked` after 3 attempts. No new `needs_input` states arise. Nothing in the ralph.md "Execution" invariants, the PRD task-state semantics, or the perspective files changed, so a PRD without the flag walks pipelines exactly as before this task.

The `needs_input` status is still recognized when the flag is off — but only in the read direction (draining a stale state cleanly). Nothing in the off-path actively mentions questions to the agent.

## Verification performed

- `grep -r needs_input framework/` returns hits only in `framework/ralph.md` and `framework/processes/prd.md` (seed.md keeps the principle framing and deliberately doesn't name the status — documentation of status names lives in ralph.md/prd.md per design §6). No leakage into perspective files, mode files, or `templates/prd.json`.
- `grep -r questions framework/` returns the four expected files (ralph.md, prd.md, seed.md, templates/prd.json). No other touches.
- `framework/templates/prd.json` parses as valid JSON (verified with `node -e "JSON.parse(...)"`).
- The seed.md addition reads complementary to the existing "Autonomy" principle — the explicit line "this is not a substitute for autonomy" makes the relationship unambiguous.
- Dry-run simulation (flag on): agent writes `questions/001.md`, sets step `needs_input`, returns → Ralph sees per ralph.md that the step is not dispatchable, dispatches other tasks → when dry, reads the unanswered file (no `## Answer`), surfaces it batched with the header → human answers → Ralph appends under divider, flips to `pending`, re-dispatches → agent reads the file on resume and proceeds. Every step follows from the written files.
- Dry-run simulation (flag off): ralph.md explicitly says do not inject the paragraph when the flag is absent or false. Agent never sees the mechanism. Path is identical to pre-task.
- Files that should not change are untouched: all `framework/perspectives/*`, all `framework/modes/code/*`, all other files under `framework/processes/`. Verified by focused grep and by enumerating edits.

## Deviations from design

None. Section structure, flag name, status name, file path convention, divider marker, and the placement of each edit match design §6 and §8.
