# Execution Strategies

Ralph can run in two modes. Both share `.ralph/ralph.md` as the single source of truth for core instructions (startup, roles, execution invariants, branch/PR). Mode-specific behavior is handled by thin wrappers.

## Subagent Mode (Subscription Plan)

For interactive Claude sessions (Claude Max subscription). No bash wrapper needed.

1. Start a Claude Code session in your project
2. Run `/ralph ralph-context/prds/your-feature.json`
3. The `/ralph` skill points Ralph to `.ralph/ralph.md` (core instructions) plus the subagent-mode section within it
4. Each perspective (planner, architect, implementer, code-cleaner, etc.) is a subagent with clean context
5. Ralph coordinates, commits, and pushes when done

**Advantages:** Works on subscription. Clean context per task. Interactive -- you can interrupt.

**Setup:** Install the framework to your project (`install.sh` copies `.ralph/`, `.claude/skills/`, and scaffolds `ralph-context/`).

## Bash Loop Mode (API / Docker)

For headless execution in Docker containers. Uses `claude -p` (print mode).

1. Enter the Docker container: `ralph-start.sh /path/to/project`
2. Run: `./ralph-loop.sh prds/your-feature.json 20`
3. Each iteration reads `RALPH_PROMPT.md` (a thin wrapper that points to `.ralph/ralph.md`) and completes one pipeline step
4. Loop continues until all tasks done or max iterations reached

**Advantages:** Unattended. Can run overnight. Docker isolation.

**Setup:** Build the Docker image, install to project, authenticate inside container.

## Choosing

| Factor | Subagent Mode | Bash Loop Mode |
|--------|---------------|----------------|
| Plan | Subscription (Max) | API key |
| Supervision | Interactive | Unattended |
| Context | Clean per subagent | Clean per iteration |
| Cost model | Rate-limited messages | Per-token billing |
| Docker required | No | Yes |
| Core instructions | `.ralph/ralph.md` | `.ralph/ralph.md` (via `RALPH_PROMPT.md`) |
