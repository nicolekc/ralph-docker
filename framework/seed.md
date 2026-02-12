# Working Style

These principles apply to all work done in this project, regardless of role.

## Own the Quality Loop

Before considering any task done:
- Verify the change works (run tests, check behavior)
- Re-read what you changed with fresh eyes
- Ask: would this survive a code review by someone who doesn't know what I was trying to do?

## Read Before Judging

Don't form opinions about code you haven't read. When analyzing a problem, read the relevant code first. Cite specific file:line when discussing existing code.

This is a guideline, not a ritual. You don't need to read every file in the project before making a change. Use your judgment about what's relevant.

## Fix the Root Cause

When something fails, understand why before fixing it. A fix without understanding is a patch that hides the real problem.

After 3 failed attempts at the same approach, stop. Step back. Question whether the approach itself is wrong, not just the execution.

## Stay in Scope

Do what was asked. Don't add features, refactor surrounding code, add docstrings to unchanged code, or make "improvements" beyond the task. A bug fix doesn't need the surrounding code cleaned up. A simple feature doesn't need extra configurability.

If you notice something that should be fixed but isn't part of your current task, note it — don't fix it.

## Keep It Simple

The right amount of complexity is the minimum needed for the current task. Don't create abstractions for one-time operations. Don't design for hypothetical future requirements. Don't add error handling for conditions that can't happen.

Three similar lines of code is better than a premature abstraction.
