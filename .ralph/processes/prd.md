# PRD Process

Any agent working on a PRD task follows these rules.

## Pipeline Model

Every task has a `pipeline` — an ordered array of steps. Each step has a `role` and a `status`. The pipeline is populated by the **planner** role as the first thing that happens to any task.

```json
"pipeline": [
  {"role": "plan", "status": "complete"},
  {"role": "architect", "status": "complete"},
  {"role": "implementer", "status": "in_progress"},
  {"role": "code-reviewer", "status": "pending"}
]
```

The human wrote the task. The planner wrote the pipeline. You work the next pending step.

### Your Step

When you pick up a task, find the first step with `"status": "pending"`, confirm it matches your role, and do the work. When done, set your step to `"complete"`, commit the PRD update, and push.

If your role isn't the next pending step, pick a different task.

### Planning

Every task starts with planning. The planner reads the task and decides which roles need to process it, in what order. The planner writes the full pipeline array with all subsequent steps as `"pending"` and the plan step as `"complete"`.

A task with an empty pipeline hasn't been planned yet.

## Task States

- **draft** — Not ready. Skip entirely.
- **pending** — Ready to be planned. Empty pipeline.
- **in_progress** — Pipeline is being walked.
- **complete** — All pipeline steps done.
- **blocked** — Stuck after repeated attempts. Reason recorded in task folder.
- **split** — Replaced by sub-tasks. Do not process.
- **redo** — Human wants it redone. Clear pipeline, re-plan with their feedback.

## Splitting

The architect is the only role that can split a task. When a task is too large or spans multiple concerns:

- Add sub-tasks to the PRD: `003` becomes `003a`, `003b`, `003c`.
- Mark the parent `"status": "split"`.
- Each child starts with an empty pipeline — it enters from planning like any other task.
- Create a folder per sub-task in `ralph-context/tasks/<prd-name>/` with enough context that the sub-task is self-sufficient.

## Durable Context

Each task gets a folder at `ralph-context/tasks/<prd-name>/<task-id>/`. Read what's there. Write what the next role needs. No prescribed format.

## Modifying the PRD

You may:
- Update your pipeline step status.
- Add sub-tasks (architect only, via splitting).
- Add new tasks you discover are needed (with empty pipeline, status `"pending"`).
- Mark tasks `blocked` with a reason.

You may not:
- Delete tasks.
- Modify completed tasks.
- Change another task's pipeline.

## Review Loops

If a code-reviewer flags issues, the implementer gets another pass. Max 3 rounds. After 3, mark blocked.

## Signoff Gates

A PRD may have a `signoff` field that limits how far pipelines are walked:

- `"plan"` — Only run planning.
- `"architecture"` — Walk up to and including architect.
- `"implementation"` — Walk up to and including implementer.
- `"full"` (default) — Walk full pipelines.

## Branch and PR

One branch per PRD: `ralph/<prd-name>`. One PR per PRD.

Create the PR after the first completed pipeline step — don't wait until the end. The PR is a living view of progress. Each runner pushes after finishing their work so the PR stays current.

The PR evolves with every push. The human can review the PRD file on the PR at any time to see pipeline progress, new tasks from splitting, and task states.
