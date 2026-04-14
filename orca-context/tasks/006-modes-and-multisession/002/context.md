# Task 002 — Mode System: Brainstorming

Architect decides the actual structure. This captures the layering idea discussed.

## Proposed directory structure

```
framework/
  seed.md                    # universal principles only
  perspectives/              # general roles only (architect, planner, etc.)
  processes/                 # pipeline engine (general)
  modes/
    code/
      seed.md                # code-specific principles (TDD, commits, etc.)
      perspectives/          # implementer, code-cleaner, code-reviewer, explorer
      (something declaring available roles + pipeline patterns)
```

## Loading chain

1. Ralph reads PRD, sees `"mode": "code"`
2. Loads base seed.md + mode seed.md
3. When dispatching, loads base perspective OR mode perspective depending on role
4. Planner reads base roles + mode roles to compose pipelines

## Key constraint from user

"It's just layered files, not a complex web." No plugin architecture, no registry, no dynamic loading. A new mode = a new directory with the right files.

## Open questions

- How does the planner discover mode-specific pipeline patterns? A file in the mode directory? Or does the mode seed.md include them?
- The `ralph-context/overrides/` pattern already does project-level layering. Modes are framework-level layering. Are these the same mechanism or distinct?
- Should modes be composable (`"modes": ["code", "research"]`) or single (`"mode": "code"`)? User mentioned composability. If composable, what happens when two modes define the same role?
