# Bootstrap Plan: Perspectives, Unified Orchestrator, Principles

## Goal
Minimal changes so the framework can orchestrate its own further development. Once these are done, everything else happens through the framework itself.

---

## 1. Extract Perspectives from Roles (Soft/Hard Skill Separation)

**The insight**: Current role files (architect.md, code-reviewer.md, etc.) mix two things:
- **Soft skills** — how to think, what lens to apply. Context-independent. Safe to load anywhere.
- **Hard skills** — what to produce, what format, who dispatched you. Process-specific.

These need to be separated because:
- A CLAUDE.md should be able to say "pick the right perspective" without loading confusing process instructions
- A subagent dispatched by Ralph should get the perspective + Ralph-specific output instructions
- A subagent dispatched by some other framework should get the same perspective + different output instructions
- An ad-hoc human session should be able to load a perspective without getting told "produce a brief approach document"

**Files to create** (under `framework/perspectives/`):
- `architect.md` — How to analyze systems, evaluate tradeoffs, think structurally. Stripped of "What You Produce" (that's a hard skill for the process to specify).
- `code-reviewer.md` — How to evaluate code: correctness then quality. Keep the two-stage thinking pattern. Remove output format prescription (approved/issues template belongs in the process).
- `design-reviewer.md` — How to evaluate designs. Already mostly a pure perspective. Light cleanup.
- `spec-reviewer.md` — How to evaluate specs. Already mostly a pure perspective. Light cleanup.
- `explorer.md` — How to trace codebases: entry points, call chains, layers. Inspired by feature-dev's code-explorer agent, which is already essentially a pure soft skill.

**What happens to `framework/roles/`**: Goes away. The perspectives replace the soft skill content. The hard skill content (output format prescriptions) moves into the orchestrator's dispatch language — ralph.md tells the subagent "apply the architect perspective and produce X" rather than the perspective file saying "you produce X."

**Key principle**: A perspective file should be safe to load in ANY context — ad-hoc session, subagent, different orchestrator, CLAUDE.md role selection. It never tells you what to produce or who dispatched you.

---

## 2. Adapt `ralph.md` for Single-Agent Subagent Orchestration

**The point of a "ralph" runner**: Instructions a human can launch that follow the Ralph process FROM WITHIN a single agent using subagents, compliant with Claude subscription plan TOS (no external automated wrapper).

**What**: Rewrite `ralph.md` so it works as instructions for a single Claude session that dispatches subagents via the Task tool. The bash-loop paradigm (one task per `claude -p` invocation) stays as a separate execution mode, but routes through the same core instructions.

**Key changes**:
- Ralph reads the PRD, works through ALL incomplete tasks (not one-per-iteration)
- For each task, dispatches subagents as the build cycle requires. No agent works on more than one task. Within a task, Ralph dispatches as many perspective-based subagents as needed (architect, implementer, reviewer — each gets one perspective and one task).
- Subagent dispatch is NOT dynamic prompt composition. Ralph says: "Follow the build cycle at `.ralph/processes/build-cycle.md`. Apply the architect perspective from `.ralph/perspectives/architect.md`. Read task context at `ralph-context/tasks/<prd>/<task>/`. The task is: [description]." The agent reads the files itself. Composition happens in the agent's context.
- No prescribed output formats in perspectives — the perspective guides thinking, the process step tells the agent what to produce if needed.
- Proportionality: Ralph decides whether a task needs the architect phase or can go straight to implementation. A rename doesn't need architecture analysis. A system redesign does. This is Ralph's judgment, not a menu of processes.
- Context flows through the shared task directory. Each agent reads what's there, adds what the next agent needs. Small task = thin context. Large task = rich context. No prescribed files or formats in the directory.
- Circuit breaker stays (3 rounds max, then block and move on)
- Parallel independent tasks: Ralph can dispatch multiple subagent chains simultaneously when tasks have no dependencies. No agent crosses task boundaries.
- Push branch when all tasks complete or all remaining are blocked

**Mode-specific behavior** (documented in ralph.md):

| | Bash Loop Mode | Subagent Mode |
|---|---|---|
| Tasks per invocation | ONE (loop restarts you) | ALL incomplete tasks |
| Completion signal | `<promise>COMPLETE</promise>` (bash script detects substring) | Just finish — the parent agent recognizes semantically there are no more tasks |
| How work gets done | You ARE the agent, do the work directly | Dispatch subagents via Task tool, one task per subagent chain |
| Who runs tests/commits | You | The subagent |

**RALPH_PROMPT.md**: Becomes a thin wrapper that routes to ralph.md. Something like: "Read `.ralph/ralph.md` for your full instructions. You are running in bash-loop mode. The PRD file is: [from bash script]." This keeps ralph-loop.sh and ralph-once.sh working unchanged.

**The `/ralph` skill** (`.claude/skills/ralph/SKILL.md`): Points to ralph.md with a note that the skill runs in subagent mode.

---

## 3. State the Principles Explicitly

**Where**: `framework/seed.md` gets additions. These are principles that travel with the framework to any target project.

**Add**:
- **Autonomy**: Work until done. Don't ask for permission to proceed, confirmation of approach, or selection between options. Make the best decision and move forward. Stop only when: (1) done, (2) truly blocked on something you cannot solve or work around (e.g. missing credentials, ambiguous requirement that can't be inferred), or (3) the human asks you to stop. No "present 3 options to the user." No "you MUST ask the user their preference at this point."
- **Proportionality**: Match effort to task complexity. A rename doesn't need architecture analysis. A system redesign does. The agent decides what's proportionate — no external process prescribes it. Context scales naturally with task complexity.
- **Shared context**: Task directories accumulate context naturally. Read what's there before starting. Write what the next agent needs when you're done. No prescribed formats or filenames.

**What stays the same**: Own the Quality Loop, Read Before Judging, Fix the Root Cause, Stay in Scope, Keep It Simple — all good as-is.

---

## 4. CLAUDE.md Role Selection

At the top of CLAUDE.md (both in ralph-docker and in the template for target projects):

```
Before starting any task, select the most appropriate perspective from
`.ralph/perspectives/` and apply it to your work. Always load `seed.md`
as your base working style.
```

This works because perspectives contain NO hard skills. No confusing dispatch instructions. No "produce format X." Just "how to think." Any orchestrator, any framework, any ad-hoc session can safely load them.

---

## 5. Installation = Description, Not Script

Replace `install.sh` with a natural language description of what a project looks like when Ralph is installed. An agent follows the description to set up any project. We describe WHAT (the end state), not HOW (the commands).

The description covers: what directories exist, what files are in them, where they come from. An agent or skill reads this and figures out the mechanics.

---

## 6. Clarify the framework/ Boundary

State explicitly (in docs, probably structure.md) that `framework/` IS the separation line:

**Installed into target projects** (travels with the framework):
- `framework/seed.md` → `.ralph/seed.md`
- `framework/perspectives/` → `.ralph/perspectives/`
- `framework/ralph.md` → `.ralph/ralph.md`
- `framework/processes/build-cycle.md` → `.ralph/processes/build-cycle.md`
- `framework/templates/` → `.ralph/templates/`

**Specific to developing Ralph** (stays in ralph-docker):
- `docs/design-principles.md` — P1-P11 for designing the framework itself
- `docs/structure.md`, `docs/execution-strategies.md`
- `CLAUDE.md` — ralph-docker project context
- `ralph-context/` — PRDs, knowledge, task context for Ralph development
- Docker/bash infrastructure — `ralph-loop.sh`, `ralph-start.sh`, etc.

---

## What Does NOT Change

- **`framework/processes/build-cycle.md`** — Still describes the default pattern (architect → implement → review). Ralph uses judgment about when to skip steps.
- **`framework/templates/prd.json`** — Fine as-is.
- **`ralph-context/` structure** — Task directories already exist and work as the shared context mechanism.
- **`.ralph-tasks/` pattern** — Ephemeral workspaces stay.
- **`ralph-loop.sh`, `ralph-once.sh`** — Bash loop stays, routes through ralph.md via thin RALPH_PROMPT.md wrapper.
- **`ralph-start.sh`, `ralph-clone.sh`, `ralph-reset.sh`** — Docker/bash infrastructure stays.
- **`.claude/skills/discover/`, `.claude/skills/refine/`** — No changes.
- **Task states** — Same: draft, pending, in_progress, complete, blocked, needs_human_review, redo.
- **Signoff gates** — Same.
- **Circuit breaker** — Same.
- **Branch and push hygiene** — Same.

---

## File-by-File Summary

**Create**:
- `framework/perspectives/architect.md` (extracted from roles/architect.md)
- `framework/perspectives/code-reviewer.md` (extracted from roles/code-reviewer.md)
- `framework/perspectives/design-reviewer.md` (extracted from roles/design-reviewer.md)
- `framework/perspectives/spec-reviewer.md` (extracted from roles/spec-reviewer.md)
- `framework/perspectives/explorer.md` (new, inspired by feature-dev code-explorer)

**Rewrite**:
- `framework/ralph.md` — Merge bash-loop instructions from RALPH_PROMPT.md, add subagent mode, reference perspectives instead of roles in dispatch language
- `RALPH_PROMPT.md` — Thin wrapper pointing to `.ralph/ralph.md` in bash-loop mode
- `.claude/skills/ralph/SKILL.md` — Point to ralph.md, clarify subagent mode
- `CLAUDE.md` — Add role selection at top, clarify framework/ boundary

**Replace**:
- `install.sh` — Natural language description of the installation end-state instead of a shell script

**Update**:
- `docs/execution-strategies.md` — Reflect unified prompt and both modes
- `docs/structure.md` — Clarify framework/ boundary, add perspectives directory
- `framework/seed.md` — Add autonomy, proportionality, shared context principles

**Remove**:
- `framework/roles/` — Replaced by `framework/perspectives/`. The hard skill content moves into ralph.md's dispatch language.

**Leave alone**:
- `framework/processes/build-cycle.md`
- `framework/templates/`
- `ralph-context/` (all of it)
- `.ralph-tasks/`
- `ralph-loop.sh`, `ralph-once.sh`, `ralph-start.sh`, `ralph-clone.sh`, `ralph-reset.sh`
- `.claude/skills/discover/`, `.claude/skills/refine/`
- `docs/design-principles.md`

---

## Order of Operations

1. Create `framework/perspectives/` from current roles (extract soft skills, strip hard skills)
2. Rewrite `framework/ralph.md` (unified orchestrator: subagent mode + bash-loop mode, reference perspectives)
3. Add principles to `framework/seed.md` (autonomy, proportionality, shared context)
4. Simplify `RALPH_PROMPT.md` to thin wrapper
5. Update `.claude/skills/ralph/SKILL.md`
6. Add role selection to `CLAUDE.md`
7. Replace `install.sh` with natural language description
8. Remove `framework/roles/`
9. Update `docs/structure.md` and `docs/execution-strategies.md`
10. Sync `.ralph/` from `framework/`
11. Commit and push

Steps 1-3 are the substantive work. Steps 4-11 are mechanical follow-through.

---

## After Bootstrap: What the Framework Then Handles Itself

Once these changes land, the framework can orchestrate its own further development. Future work that would use the framework:
- Refining perspectives based on real execution feedback
- The parallel human-agent vision (agents work all possible tasks, block on questions, human answers unblock)
- Multi-repo orchestration (cross-project PRDs, Docker multi-mount)
- Adding the explorer perspective to the build cycle if warranted
- Any additional process variants that emerge from practice
