# PRD Refinement

Review the PRD for task sizing and acceptance criteria quality.

## Right-Sized Task
- Completable in one focused session
- Has clear "done" state (testable)
- Dependencies are explicit

## Too Big (split it)
- Has multiple distinct deliverables
- Naturally breaks into "first X, then Y"

## Too Small (merge it)
- Just a sub-step of another task
- Can't be tested independently

## Task Order

Task IDs are for REFERENCE ONLY--not execution order.
Ralph picks the best next task dynamically based on:
- What's already done
- What makes logical sense
- Dependencies between tasks

If tasks have hard dependencies, note them in the description:
- "Requires: 003" or "After auth is complete"
- Do NOT assume numeric order = execution order

## Acceptance Criteria Quality

Good criteria test PURPOSE, not implementation:
- "User can log in with email/password" (purpose)
- "Login form calls /api/auth endpoint" (implementation - too rigid)

Avoid:
- Specifying exact function names or file structures
- Requiring specific libraries or patterns
- Testing internal state rather than observable behavior

## Output Format

For each task:
- KEEP: [task id] - [reason]
- SPLIT: [task id] into [subtasks]
- MERGE: [task ids] into [single task]
- FIX: [task id] - [criteria issue]

Or if all tasks are ready: "PRD is ready"
