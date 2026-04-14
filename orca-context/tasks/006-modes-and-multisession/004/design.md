# Task 004 Design — Non-Blocking Question Mechanism

## 1. Mechanism Overview

End-to-end flow when a subagent hits genuine ambiguity it can't resolve from context:

1. **Agent writes a question.** In the task context folder, the agent creates `questions/NNN.md` (NNN = next free 3-digit index). The file is freeform markdown — one or two paragraphs describing what's ambiguous, what the agent considered, and (if useful) a concrete recommendation the human can accept by default.
2. **Agent parks its step.** The agent sets its own pipeline step status to `needs_input` in the PRD JSON, commits and pushes, and returns to Ralph without completing the step.
3. **Ralph keeps dispatching.** On the next dispatch decision, Ralph re-reads the PRD. `needs_input` steps are parked — treated as "not dispatchable right now" but not terminal. Ralph dispatches any other ready work: other tasks with `pending` next-steps, no unmet dependencies.
4. **Ralph surfaces when dry.** When no task has a dispatchable step (everything is `complete`, `blocked`, `split`, or parked at `needs_input`), Ralph collects every unanswered question file across all `needs_input` steps and presents them to the human in one batch.
5. **Human answers.** The human replies in the same chat turn. Ralph writes each answer to the matching question file (see §3 for format), flips those pipeline steps from `needs_input` back to `pending`, commits, and re-dispatches.
6. **Agent resumes.** The re-dispatched agent sees the same step as `pending` again. Before starting, it reads `questions/` in the task folder — prior roles' task-context-folder rule already drives this. It finds the answered file, incorporates the answer, completes the step normally.

Questions are per-step, not per-task — the same task can accumulate several across its pipeline (architect asks one, later implementer asks another). They live in the task folder because that's where the answer is needed next.

## 2. Step Status `needs_input`

**New step status**, alongside `pending`, `in_progress`, `complete`. Task-level status stays `in_progress` — the task is not parked, a specific step is.

Semantics:

- **Set by:** the subagent currently working the step, when it decides to ask rather than push through or block.
- **Means:** this step is waiting on a human answer. Do not dispatch. Do not count toward the 3-attempt limit — it's a pause, not a failure.
- **Cleared by:** Ralph, after the human answers. Ralph sets the step back to `pending` and the next dispatch picks it up again.
- **Dispatch effect:** Ralph treats `needs_input` like `complete` for the purpose of "is there dispatchable work?" — it's not dispatchable, but unlike `blocked` it will become dispatchable again.
- **Task completion:** a task cannot be `complete` while any of its steps are `needs_input`. The step has to answer-resume-finish first.

`needs_input` is strictly cleaner than piggy-backing on `blocked`: `blocked` means "3 attempts and stuck," surfaces as a failure in the completion assessment, and doesn't auto-resume. A pending-question step is none of those things.

## 3. Question / Answer File Format

**Location:** `ralph-context/tasks/<prd-name>/<task-id>/questions/NNN.md` (3-digit index, starting `001`).

Using a `questions/` subdirectory (not a flat `question.md`) keeps multiple questions per task — across different pipeline steps — from colliding. One file per question. Existing task folder contents (design.md, implementation notes, etc.) are untouched.

**Freeform markdown**, not frontmatter. Rationale: structured frontmatter (category, options, what-was-tried) is a checklist the agent will half-fill to satisfy the format. Freeform prose forces the agent to actually think about what's ambiguous. The human reads it as prose anyway. If a convention emerges later we can tighten.

Recommended shape (not enforced):

```markdown
# Question

<what's ambiguous, in 1-3 sentences>

## What I considered

<alternatives, tradeoffs, what context left unclear>

## My recommended default

<what I'd do if told "just decide" — so the human can say "yes that's fine">
```

**Answer:** appended to the same file under a divider. Ralph writes:

```markdown
---

## Answer

<human's response, verbatim>
```

One file, read top-to-bottom on re-dispatch — the agent sees its own question, what it considered, and the answer in order. No separate `answer.md` to miss.

A question file is "answered" iff it contains an `## Answer` section. Ralph uses that marker to decide which questions still need surfacing and which are resolved.

## 4. Surfacing UX

When Ralph has nothing dispatchable, it produces one message to the human containing every unanswered question:

```
No dispatchable work remaining. <N> question(s) waiting.

── Task 003 / architect ──
<contents of questions/001.md verbatim, or a clean rendering>

── Task 005 / implementer ──
<contents of questions/001.md verbatim>

Please answer inline. I'll write your answers back to the task folders and resume.
```

Rules:

- **One batch, not one-at-a-time.** Every unanswered question surfaces together. The human can reply to all of them, some of them, or none.
- **No tiering, no priorities.** The agents asked; the human decides order by reading.
- **Verbatim content.** Ralph does not summarize or rewrite the question — the agent's framing is the question. Ralph adds only the "Task X / role" header for routing.
- **Partial answers are fine.** If the human answers 2 of 3, Ralph re-dispatches the two answered ones and the third stays `needs_input` for the next surfacing round.
- **Ralph does NOT prompt the human for anything else.** No "would you like me to…" — just the questions and "answer inline."

After the human answers, Ralph writes each answer to its file (appending the `## Answer` section), flips the matching pipeline steps from `needs_input` back to `pending`, commits as one unit ("answered N question(s)"), and resumes the dispatch loop.

**Stop condition.** If every remaining task is either `complete`, `blocked`, `split`, or its pipeline is entirely at `needs_input` / `complete` AND the human is not present to answer, Ralph stops as it would today ("all tasks complete or blocked"). The wait for an answer is part of the interactive subagent session, not a background state.

## 5. PRD `questions` Field

**New PRD field, top-level:** `"questions": true | false`. **Default: `false`** (omitted = disabled = fully autonomous).

Gating is done at dispatch time, by Ralph, via the dispatch prompt it sends to each subagent:

- **If `questions: true`:** Ralph's dispatch prompt includes a short paragraph (see §6, ralph.md change) telling the agent it may write a question to `questions/NNN.md` and set its step to `needs_input` when it hits genuine ambiguity it can't resolve from context. The agent learns the capability exists.
- **If `questions: false` or omitted:** the paragraph is not injected. The agent never learns about the mechanism. It uses the existing options: best judgment, or mark `blocked` after 3 attempts.

This keeps the gate clean: there is no "allowed but discouraged" middle state. The agent either knows about questions or doesn't.

Ralph still recognizes `needs_input` as a step status regardless of the flag, because the mechanism must drain cleanly if a PRD is flipped mid-run or if a stale `needs_input` survives from a prior session. But when the flag is off, no new `needs_input` states arise because the agents don't know to produce them.

**Planner is not aware of the flag.** The planner composes pipelines from roles; the question mechanism is a runtime capability of any role, not a pipeline shape. The flag lives entirely between Ralph and the dispatched worker.

**Base capability, not mode-specific.** Any mode can benefit — research mode agents hit ambiguity as much as code mode agents. Lives in base files (ralph.md, prd.md, templates/prd.json, seed.md). No mode files change.

## 6. File-Level Changes

All edits in `framework/` (the canonical source). No mode files change.

### `framework/ralph.md`

Add a short section **"Questions (when enabled)"** near "Execution":

- Describe the `needs_input` step status: not dispatchable, not a failure, not counted toward the 3-attempt limit.
- Describe the dispatch injection: when the PRD has `"questions": true`, the dispatch prompt to the subagent includes a paragraph describing the mechanism (write to `questions/NNN.md`, set step to `needs_input`, return). When the flag is absent or false, do not include that paragraph.
- Describe the surfacing step: when no step is dispatchable and at least one step is `needs_input`, read every unanswered `questions/NNN.md`, present them to the human in one batch, write answers back with an `## Answer` divider, flip the steps to `pending`, resume.
- Note that `needs_input` does not count toward "3 attempts then blocked."

Roughly 15–25 lines. Keep it principles-first — don't script the exact wording Ralph uses to the human.

### `framework/processes/prd.md`

Two additions:

1. In **Pipeline Model → Your Step** (or a new "Step Statuses" subsection): document `needs_input` as a step status. Short: "Set by the worker when it hits ambiguity it can't resolve from context and the PRD enables questions. The step is parked until a human answers; then Ralph flips it back to `pending`. Does not count toward the 3-attempt limit."
2. A new short section **"Questions"** (below Durable Context, above Modifying the PRD):
   - The PRD may declare `"questions": true` to enable the mechanism. Default is off.
   - When enabled and an agent decides to ask, it writes `questions/NNN.md` in the task folder (freeform markdown), sets its step to `needs_input`, and returns.
   - Answers are appended to the same file under an `## Answer` divider.
   - Ralph surfaces questions to the human in batch when no other work is dispatchable.

### `framework/seed.md`

Add one short section, **"Questions (when enabled)"**, to the principles. Roughly:

> Some PRDs allow you to ask a clarifying question instead of guessing when you hit genuine ambiguity — intent, requirements, or a judgment call that really needs the human. When the dispatch prompt tells you questions are enabled, use them sparingly: only when you've actually tried to resolve the ambiguity from context and can't, and only when the cost of guessing wrong is larger than the cost of waiting. If questions aren't enabled, make the best call you can or mark the task blocked after 3 attempts.

Principle, not a checklist. No rules about format (format lives in prd.md), no counter, no tiers.

### `framework/templates/prd.json`

Add `"questions": false` at the top level, alongside `"mode"` and `"signoff"`. Explicitly false (not omitted) so new PRDs show the field and the human sees it exists.

### No changes

- Perspective files (`architect.md`, `drafter.md`, `implementer.md`, etc.) — the capability is general; injecting into dispatch prompts keeps the perspective files stable.
- Mode files (`modes/code/MODE.md`) — base feature.
- Planner perspective — not aware of the flag.

## 7. Anti-Crutch Guardrails

**No hard per-task question cap.** Reasoning:

- The existing 3-attempt limit already covers the "agent is spinning" case.
- A cap would just push agents back to bad guesses when they've exhausted their quota on real ambiguity.
- The real guardrail is the seed.md principle ("only when you've actually tried to resolve from context") plus the PRD-level opt-in (a PRD that doesn't want questions doesn't get them at all).
- If crutching emerges in practice, add the cap then. Don't pre-empt with speculative mechanics.

**`needs_input` does not count toward the 3-attempt limit.** Confirmed from the brainstorm. A pause is not a failure.

**No re-evaluation before surfacing.** If Task B's completion happens to resolve Task A's question, Ralph does not detect that. The question still surfaces. The human can answer "moot, other task resolved this" and the agent re-dispatches with that answer and proceeds. Re-evaluation is speculative complexity (P3 Specification-Creativity Tradeoff) — trust the human to recognize a moot question in 2 seconds.

**No structured frontmatter.** Freeform prose is the guardrail against checkbox-completion-as-thought.

## 8. Implementer Scope

Create:

- No new files. Question files are created at runtime by agents.

Edit:

- `framework/ralph.md` — add the "Questions (when enabled)" section as specified in §6.
- `framework/processes/prd.md` — add `needs_input` to step-status documentation, add the "Questions" section.
- `framework/seed.md` — add the short "Questions (when enabled)" principle.
- `framework/templates/prd.json` — add `"questions": false` at top level.

Do **not** edit:

- Perspective files
- `framework/modes/code/MODE.md`
- `.ralph/` (installed copy — sync is a separate concern)
- Any PRD except to advance the pipeline for task 004

Keep edits minimal. Every addition above is small — a short section or single field. Resist the urge to over-specify the dispatch-prompt wording or the surfacing-message wording. State the principles and the mechanics (status names, file paths, flag name, divider convention); leave the prose that Ralph generates to Ralph.

## 9. Verification Strategy

No real Ralph-loop test harness exists, so verification is by simulation and inspection.

1. **Dry-run simulation, flag on.** Construct a small mock PRD with `"questions": true` and two tasks, A and B, with no dependencies. Walk through the dispatch loop by hand:
   - Imagine A's architect hitting ambiguity. It writes `questions/001.md`, sets step to `needs_input`, returns.
   - Ralph's next decision: re-read PRD, see A's step is `needs_input`, see B is dispatchable. Dispatch B.
   - B completes. Ralph re-evaluates: no dispatchable work, one `needs_input` step, surface the question.
   - Human answers inline. Ralph appends `## Answer` to the file, flips A's step to `pending`. Re-dispatches.
   - A's architect picks up, reads the file, proceeds.
   Every step should follow from ralph.md and prd.md as written.

2. **Dry-run simulation, flag off.** Same PRD but `"questions": false` or field omitted. The dispatch prompt must not mention questions. The agent must not know the capability exists. If the agent produces a question file anyway (hypothetically), Ralph still handles `needs_input` correctly — but the intended path is "agent guesses or blocks."

3. **File-level review.** Read each edited file end-to-end with fresh eyes. Check:
   - The three documents agree on file paths, status name, divider convention, flag name.
   - `needs_input` is documented as a step status wherever step statuses are listed.
   - The seed.md principle does not contradict the existing "Autonomy" principle ("work until done, don't ask for permission") — the new text is about genuine ambiguity, not permission-seeking. Confirm the two read as complementary.

4. **PRD template check.** `framework/templates/prd.json` parses as valid JSON. A new PRD generated from the template has the field visible and set to `false`.

5. **Grep check.** `grep -r needs_input framework/` should return hits only in the three doc files (ralph.md, prd.md, seed.md). No accidental leakage into mode or perspective files.

6. **End-to-end smoke (optional, if time).** When this PRD's later tasks land and the framework syncs to `.ralph/`, a real Ralph run of a small scratch PRD with `"questions": true` and one intentionally ambiguous task will exercise the full path. Defer to integration; not a blocker for this task.

That's sufficient. The feature is a small coordination protocol across 3–4 doc files; over-testing it at design time is a waste.
