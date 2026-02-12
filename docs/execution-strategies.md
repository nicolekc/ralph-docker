# Execution Strategies

Ralph can run in two modes. The framework files are the same in both.

## Subagent Mode (Subscription Plan)

For interactive Claude sessions (Claude Max subscription). No bash wrapper needed.

1. Start a Claude Code session in your project
2. Run `/ralph prds/your-feature.json`
3. Ralph reads the PRD and orchestrates via the Task tool
4. Each architect/implementer/reviewer is a subagent with clean context
5. Ralph coordinates, commits, and pushes when done

**Advantages:** Works on subscription. Clean context per task. Interactive — you can interrupt.

**Setup:** Install the framework to your project (copies `.ralph/` and `.claude/skills/ralph/`).

## Bash Loop Mode (API / Docker)

For headless execution in Docker containers. Uses `claude -p` (print mode).

1. Enter the Docker container: `ralph-start.sh /path/to/project`
2. Run: `./ralph-loop.sh prds/your-feature.json 20`
3. Each iteration reads RALPH_PROMPT.md and completes one task
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
| Review loop | Built-in (architect→implement→review) | Single pass per iteration |
