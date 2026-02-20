# Bootstrap Plan: Perspectives + Orchestrator Adaptation

## Goal
Minimal changes so the framework can orchestrate its own further development. Three things need to happen.

---

## 1. Extract Perspectives from Roles

**What**: Split current `framework/roles/*.md` files into pure perspectives (soft skills) that contain only thinking patterns — no output format prescriptions, no process-specific instructions.

**Files to create** (under `framework/perspectives/`):
- `architect.md` — How to analyze systems, evaluate tradeoffs, think structurally. Stripped of "What You Produce" section (that's process-specific).
- `code-reviewer.md` — How to evaluate code: correctness then quality. Keep the two-stage thinking pattern. Remove "What You Produce" format prescription (approved/issues template).
- `design-reviewer.md` — How to evaluate designs. Already mostly a pure perspective. Light cleanup.
- `spec-reviewer.md` — How to evaluate specs. Already mostly a pure perspective. Light cleanup.

**What happens to `framework/roles/`**: Goes away. The perspectives replace it. The process-specific output instructions move into `ralph.md`'s dispatch language (see #2).

**Key principle**: A perspective file should be safe to load in ANY context — ad-hoc session, subagent, different orchestrator, CLAUDE.md role selection. It never tells you what to produce or who dispatched you.

---

## 2. Adapt `ralph.md` for Single-Agent Subagent Orchestration

**What**: Rewrite `ralph.md` so it works as instructions for a single Claude session that dispatches subagents via the Task tool. Replace the bash-loop paradigm (one task per `claude -p` invocation) with a persistent orchestrator that works through all tasks.

**Key changes**:
- Ralph reads the PRD, works through ALL incomplete tasks (not one-per-iteration)
- For each task, dispatches subagents using the Task tool
- Each subagent prompt says: "Load seed from `.ralph/seed.md`. Apply perspective from `.ralph/perspectives/X.md`. Read task context at `ralph-context/tasks/<prd>/<task>/`. The task is: [description]. Do your work. Write anything the next agent needs back to the task context directory."
- No prescribed output formats — the perspective guides thinking, the agent decides what to write based on task complexity
- Proportionality: Ralph decides whether a task needs architect phase or can go straight to implementation. This is Ralph's judgment, not a menu of processes.
- Autonomy principle: subagents work until done. They don't present options or ask for confirmation. They stop only when done, truly blocked, or the human intervenes.
- Context flows through the shared task directory. Each agent reads what's there, adds what the next agent needs. Small task = thin context. Large task = rich context.
- Circuit breaker stays (3 rounds max, then block and move on)
- Parallel independent tasks: Ralph can dispatch multiple subagent chains simultaneously when tasks have no dependencies
- Push branch when all tasks complete or all remaining are blocked

**What gets removed**:
- `<promise>COMPLETE</promise>` signal (that was for the bash loop)
- One-task-per-iteration language
- Prescribed output document formats for architect/reviewer
- References to RALPH_PROMPT.md

**The `/ralph` skill** (`.claude/skills/ralph/SKILL.md`): Updated to just say "You are now operating as Ralph. Read `.ralph/ralph.md` for your instructions. Your PRD file is: $ARGUMENTS" — minimal, points to the source of truth.

---

## 3. State the Principles Explicitly

**Where**: `framework/seed.md` gets a few additions. These are principles that travel with the framework to any target project.

**Add**:
- **Autonomy**: Work until done. Don't ask for permission to proceed, confirmation of approach, or selection between options. Make the best decision and move forward. Stop only when: done, truly blocked on something you cannot solve or work around, or the human asks you to stop.
- **Proportionality**: Match effort to task complexity. A rename doesn't need architecture analysis. A system redesign does. The agent decides what's proportionate — no external process prescribes it.
- **Shared context**: Task directories accumulate context naturally. Read what's there before starting. Write what the next agent needs when you're done. No prescribed formats.

**What stays the same**: Own the Quality Loop, Read Before Judging, Fix the Root Cause, Stay in Scope, Keep It Simple — all good as-is.

---

## What Does NOT Change

- `framework/processes/build-cycle.md` — Still describes the default pattern (architect -> implement -> review). But it's a reference, not a mandate. Ralph uses judgment.
- `framework/templates/prd.json` — Fine as-is.
- `ralph-context/` structure — Fine as-is. Task directories already exist.
- `docs/` — These are ralph-docker-specific, not installed into target projects. No changes needed now.
- `.claude/skills/discover/` and `.claude/skills/refine/` — No changes needed.

---

## What Gets Cleaned Up

- `RALPH_PROMPT.md` — No longer needed (was for bash loop). Can be removed or archived.
- `ralph-loop.sh`, `ralph-once.sh`, `ralph-reset.sh`, `ralph-clone.sh` — Bash loop infrastructure. Not needed for subagent mode. Can be removed or moved to a `legacy/` directory.
- `ralph-start.sh` — Docker startup. Still useful if someone wants Docker isolation, but not part of the core framework.
- `install.sh` — Replace with a natural language description of the installation end-state (what a project looks like with Ralph installed). An agent follows the description. Not a script.
- `framework/roles/` — Replaced by `framework/perspectives/`.

---

## File-by-File Summary

**Create**:
- `framework/perspectives/architect.md`
- `framework/perspectives/code-reviewer.md`
- `framework/perspectives/design-reviewer.md`
- `framework/perspectives/spec-reviewer.md`

**Rewrite**:
- `framework/ralph.md` (single-agent subagent orchestrator)
- `framework/seed.md` (add autonomy, proportionality, shared context principles)
- `.claude/skills/ralph/SKILL.md` (minimal, point to ralph.md)

**Remove**:
- `framework/roles/` (replaced by perspectives)
- `RALPH_PROMPT.md` (bash loop artifact)
- `install.sh` (replace with description, not script)

**Remove or archive** (human decision — these are bash loop infrastructure):
- `ralph-loop.sh`
- `ralph-once.sh`
- `ralph-reset.sh`
- `ralph-clone.sh`

**Leave alone**:
- `framework/processes/build-cycle.md`
- `framework/templates/prd.json`
- `ralph-context/` (all of it)
- `docs/` (all of it)
- `.claude/skills/discover/`, `.claude/skills/refine/`
- `CLAUDE.md` (update later once structure settles)
- `ralph-start.sh` (Docker, still useful)

---

## Order of Operations

1. Create `framework/perspectives/` from current roles (extract soft skills)
2. Rewrite `framework/ralph.md` for subagent orchestration
3. Add principles to `framework/seed.md`
4. Update `.claude/skills/ralph/SKILL.md`
5. Remove `framework/roles/`, `RALPH_PROMPT.md`, `install.sh`
6. Update CLAUDE.md to reflect new structure
7. Commit and push

Steps 1-3 are the substantive work. Steps 4-7 are mechanical follow-through.
