# Bootstrap Plan: Subagent Execution Mode + Unified Prompt

## Goal
Add a second execution mode (subagent orchestration via Task tool) alongside the existing bash loop. Both modes use the same core instructions. All behavior stays the same — same roles, same build cycle, same state management. The difference is only the execution mechanism.

---

## What Changes

### 1. Unify the prompt: `ralph.md` becomes the single source of truth

**Currently**: Two separate instruction sets exist:
- `framework/ralph.md` — describes subagent orchestration but was never actually executed
- `RALPH_PROMPT.md` — the real instructions, used by the bash loop via `claude -p`

These overlap, contradict each other in places, and duplicate logic.

**Change**: Merge them. `framework/ralph.md` becomes THE instructions for Ralph, usable by both execution modes. It contains:
- How to read the PRD, pick the next task, run the build cycle
- All the rules (one task at a time, circuit breaker, branch hygiene, task state, etc.)
- Mode-specific behavior at the end: a short section explaining what differs between bash-loop mode and subagent mode

**Mode differences (documented in ralph.md)**:
| | Bash Loop Mode | Subagent Mode |
|---|---|---|
| Tasks per invocation | ONE (loop restarts you) | ALL incomplete tasks |
| Completion signal | `<promise>COMPLETE</promise>` (bash script detects substring) | Just stop — the parent agent recognizes there are no more tasks |
| Subagent dispatch | N/A (you ARE the agent, do the work directly) | ONE Task tool call per task — the subagent runs the full build cycle internally |
| Who runs tests/commits | You | The subagent |

### 2. `RALPH_PROMPT.md` becomes a thin wrapper

Instead of containing all the instructions, it becomes:
```
Read .ralph/ralph.md for your full instructions. You are running in bash-loop mode.
The PRD file is: [provided by the bash script]
```

This keeps `ralph-loop.sh` and `ralph-once.sh` working unchanged — they still pass `RALPH_PROMPT.md` to `claude -p`.

### 3. One subagent per task (subagent mode)

In subagent mode, Ralph dispatches ONE subagent per task using the Task tool. That subagent:
- Reads the role prompts (architect, code-reviewer) as needed
- Runs the full build cycle internally (architect phase → implement → review → fix loops)
- Commits when passing
- Returns when the task is complete or blocked

Ralph does NOT dispatch separate architect/implementer/reviewer subagents. One agent does the whole thing for one task, then the subagent closes.

When there are no more incomplete tasks, the parent Ralph agent finishes. No special signal needed — it can tell semantically.

### 4. Update the `/ralph` skill

`.claude/skills/ralph/SKILL.md` already points to `.ralph/ralph.md`. Update it to clarify that the skill runs Ralph in subagent mode (dispatching via Task tool). Keep the quick reference but align it with the unified ralph.md.

### 5. Update `docs/execution-strategies.md`

Currently describes both modes but the details are out of date. Update to reflect the unified prompt and clarify the actual differences between modes.

---

## What Does NOT Change

- **`framework/roles/`** — All four roles stay exactly as they are (architect, code-reviewer, design-reviewer, spec-reviewer). Same content, same "What You Produce" sections.
- **`framework/processes/build-cycle.md`** — Same build cycle.
- **`framework/seed.md`** — Same principles.
- **`framework/templates/prd.json`** — Same PRD format.
- **`ralph-loop.sh`, `ralph-once.sh`** — Same bash scripts. They still work by invoking `claude -p` with RALPH_PROMPT.md.
- **`ralph-start.sh`** — Docker startup stays.
- **`ralph-clone.sh`, `ralph-reset.sh`** — Stay.
- **`install.sh`** — Stays (it copies framework files to target projects).
- **`ralph-context/` structure** — All task context, knowledge, designs, PRDs stay.
- **`.ralph-tasks/` pattern** — Ephemeral workspaces stay.
- **`.claude/skills/discover/`, `.claude/skills/refine/`** — No changes.
- **Task states** — Same: draft, pending, in_progress, complete, blocked, needs_human_review, redo.
- **Signoff gates** — Same: architecture, implementation, full.
- **Circuit breaker** — Same: 3 rounds max.
- **Non-code deliverables** — Same handling.
- **Branch and push hygiene** — Same.

---

## File-by-File Summary

**Rewrite**:
- `framework/ralph.md` — Merge RALPH_PROMPT.md logic into it. Add mode-switching section at the end. This is the substantive work.

**Simplify**:
- `RALPH_PROMPT.md` — Becomes a thin wrapper pointing to `.ralph/ralph.md`

**Update**:
- `.claude/skills/ralph/SKILL.md` — Clarify subagent mode, align with unified ralph.md
- `docs/execution-strategies.md` — Update to match new reality

**Leave alone** (everything else):
- `framework/roles/*`, `framework/processes/*`, `framework/seed.md`, `framework/templates/*`
- `ralph-loop.sh`, `ralph-once.sh`, `ralph-start.sh`, `ralph-clone.sh`, `ralph-reset.sh`
- `install.sh`
- `ralph-context/`, `.ralph-tasks/`
- `.claude/skills/discover/`, `.claude/skills/refine/`
- `CLAUDE.md`

---

## Order of Operations

1. Rewrite `framework/ralph.md` (merge both instruction sets, add mode section)
2. Simplify `RALPH_PROMPT.md` to thin wrapper
3. Update `.claude/skills/ralph/SKILL.md`
4. Update `docs/execution-strategies.md`
5. Sync `.ralph/` from `framework/` (keep installed copy current)
6. Update CLAUDE.md if needed
7. Commit and push

Step 1 is the real work. Steps 2-7 are mechanical.

---

## Open Questions / Possibly Missing Items

> From the conversation: "weren't there more things to do? Looking up through our most recent messages, I don't think that was all captured."

The branch name (`multi-repo-selection`) and `ralph-context/tasks/004-framework-evolution/004/docker-multi-repo.md` suggest multi-repo orchestration was discussed. That topic is NOT covered in this plan. What else was discussed that should be here?
