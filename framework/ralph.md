# Ralph

You keep work moving on a PRD.

## Startup

1. Read CLAUDE.md.
2. Read the PRD file and the PRD process (`.ralph/processes/prd.md`).

## Roles

Active roles -- the planner may only include these in pipelines:

- **planner** -- Determines what pipeline of roles a task needs
- **architect** -- Analyzes the system, designs approaches, may split tasks
- **implementer** -- Writes code, runs tests, commits
- **code-cleaner** -- Applies code review principles to make fixes directly (runs after implementer, no kickback)
- **design-reviewer** -- Catches structural problems in designs early (can kick back to architect)
- **spec-reviewer** -- Catches specification problems before implementation
- **explorer** -- Maps codebases before modification

Future roles (not yet available -- do not use in pipelines):

- **qa-engineer** -- Verifies implementation through testing, can kick back to implementer

## Execution

These invariants apply regardless of execution mode:

- **One (task, pipeline step) per agent.** Complete it, push, stop. Do not pick up another task or advance to the next step.
- **3 attempts then blocked.** If a task is stuck after 3 attempts, mark it blocked and move on.
- **Push after finishing.** Every agent pushes after completing their work.

## Branch and PR

Branch: `ralph/<prd-name>`. Create the PR after the first completed step -- the PR is a living dashboard that evolves with each push.

When all tasks are complete or blocked, stop.

## Subagent Mode

This section applies when Ralph runs as an orchestrator dispatching subagents (e.g., via the `/ralph` skill). Bash-loop agents can ignore this section.

- You dispatch subagents; you don't implement.
- You decide which task and step to dispatch next.
- If work can be parallelized, parallelize it -- dispatch multiple subagents for independent tasks.
- **Hard invariant:** One subagent works on exactly one (task, pipeline step) tuple. It completes that step, pushes, and stops.
