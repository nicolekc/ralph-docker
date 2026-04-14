# Task 004 — Question Mechanism Brainstorming

This is brainstorming from early design discussion, not a spec. The architect decides the actual changes.

## The problem

In subagent mode, when an agent hits genuine ambiguity (requirements, intent, tradeoffs that need human judgment), it has two options today: guess and keep going, or mark `blocked`. Guessing risks wasted work. Blocking is terminal and stalls dependents. There's no middle ground.

## Key design constraints (from user)

- **Non-blocking**: a question on one task must not stall other tasks
- **Batched**: questions accumulate; human answers when Ralph has nothing else to dispatch
- **PRD-level opt-in**: `"questions": true/false` on the PRD. Default false (fully autonomous). Some PRDs shouldn't allow questions at all — agents must push through or block.
- **User doesn't use bash-loop mode** — design for subagent mode (Ralph orchestrator talking to human interactively)

## Rough mechanism discussed

**Signaling**: subagent writes question to `ralph-context/tasks/<prd>/<task>/question.md`, sets its pipeline step status to `needs_input`, returns to Ralph without completing the step.

**Accumulation**: the PRD itself is the accumulator. Ralph scans for steps with `needs_input` status. Each corresponding task context directory has the question file. No separate queue or accumulation file.

**Dispatch continues**: `needs_input` tasks are parked — Ralph skips them and dispatches anything else that's ready (other tasks with `pending` steps, no unmet dependencies).

**Surfacing**: when Ralph exhausts dispatchable work (everything is complete, blocked, or `needs_input`), it reads all question files and presents them to the human in batch.

**Answering**: human answers (all at once or selectively). Ralph writes answers to task context (e.g., `answer.md` or appended to the question file). Flips step status back to `in_progress`. Re-dispatches.

**Attempt counting**: `needs_input` does NOT count toward the 3-attempt limit. It's a pause, not a failure.

**PRD gate**: if `"questions": false` (or omitted), Ralph's dispatch prompt to the agent doesn't include the "you may ask questions" instruction. The agent never learns it can ask — so it pushes through with best judgment or blocks.

## Open questions for the architect

- Is `needs_input` a step status or a task status? Step status seems cleaner (task stays `in_progress`, specific step is parked). But it's a new concept — today step statuses are only `pending`, `in_progress`, `complete`.
- Should there be a structured question format (frontmatter with category, options, what-was-tried) or just freeform markdown?
- What happens if a question becomes moot because another task's completion resolved the ambiguity? Should Ralph re-evaluate before surfacing?
- Should there be a limit on questions per task to prevent an agent from using questions as a crutch instead of thinking?
- Where does the "you may ask questions" instruction live? In seed.md? In a mode file? In the perspective? Ralph could inject it dynamically based on the PRD's `questions` field.
