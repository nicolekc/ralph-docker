# Task Context: Naming Audit

## Problem Statement

The framework's directory names and concepts were named quickly during initial development. Several are confusing, ambiguous, or carry the wrong connotation. Nicole flagged these specifically:

### Items to Audit

| Current Name | Problem |
|---|---|
| **ralph-context/** | Sounds like ralph's internal state. It's actually the framework's entire working directory — PRDs, tasks, designs, knowledge, overrides. The name implies it's subordinate to ralph, but it IS the framework. |
| **tasks/** | Ambiguous. Could mean runtime task execution, or the task context folders that live here. These are really task *contexts* (supplementary materials for each task), not the tasks themselves (those are in the PRD JSON). |
| **knowledge/** | Vague. Knowledge about what? This is meant for accumulated learnings — things discovered during execution that should persist. But "knowledge" could mean anything. |
| **overrides/** | Overrides to what? Currently holds role overrides. But the name doesn't communicate what's being overridden or why. |
| **overrides/roles/** | Actually fairly clear, but only in context of knowing what overrides/ means. |
| **designs/** | Reasonably clear. Investigation outputs and design documents land here. |
| **prds/** | Clear if you know the acronym. Might be opaque to someone new. |
| The project name | Currently "ralph-docker" because that's the test repo. Not relevant to the framework itself, but worth noting: the framework needs a name that isn't tied to a specific host project. |
| **.ralph** vs **ralph-context** | Should the framework root be a dotfile? Dotfiles signal "config/hidden." A visible directory signals "this is part of the project." Which is right? |
| **.tasks** | Nicole mentioned this as another option for the tasks directory. Dotfile convention would hide it from casual `ls`. |

### What This Investigation Should Cover

1. **Audit every named directory** in the framework root and one level deep
2. **Propose 2-3 coherent naming schemes** — each scheme should be internally consistent (don't mix metaphors)
3. **Consider the audience**: a new developer encountering this directory for the first time, a runner (AI agent) navigating by convention, a human reviewing work
4. **Flag breaking changes**: which renames would require updating seeds, role prompts, PRD references, and framework code? Which are cosmetic (no references to update)?
5. **The dotfile question**: should the framework root be hidden (`.ralph`, `.framework`) or visible (`ralph-context`, `project-context`)? What are the tradeoffs?
6. **Recommend one scheme** with honest rationale

### Naming Principles to Consider

- Names should be self-documenting to someone who has never seen the framework
- Names should be unambiguous — a name that could mean two things will eventually be misunderstood
- Internal consistency matters more than any individual name being perfect
- Shorter is better, but not at the cost of clarity
- The framework may eventually be used in projects that have nothing to do with "ralph" — names shouldn't be ralph-specific unless they refer to ralph itself
