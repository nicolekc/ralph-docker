# Task Context: Integrate Knowledge into Framework

## Problem Statement

**Discovered:** During the founding design session, several pieces of generalizable knowledge were captured in ralph-context/knowledge/. These are currently project-specific working notes, but they contain wisdom that EVERY user of ralph-docker needs. They should become part of the framework itself.

**Why it matters:** A fresh project installing ralph-docker gets framework/ (via .ralph/) but NOT ralph-context/. If the success criteria format guidance, problem statement structure, etc. only live in ralph-context/, new projects don't benefit from them.

**What was tried:** Some knowledge was already partially integrated — the spec-reviewer role was enhanced with success criteria quality checks and problem statement completeness. But the full depth of the knowledge files hasn't been absorbed into the framework.

**Constraints:**
- Don't just copy files — the knowledge needs to be integrated into the right framework files (roles, processes, templates)
- PRD_REFINE.md wisdom is battle-tested from 160+ Promptly tasks — don't lose content
- The framework files should remain concise (P8: Lightning-Quick Descriptions)
- Some knowledge depends on investigation outcomes (draft-tasks-pattern depends on PRD 003/005, two-modes depends on PRD 004/005)

## Knowledge Files to Integrate

1. **success-criteria-format.md** → Belongs in spec-reviewer role and/or PRD authoring process. The who/what/how pattern for acceptance criteria.
2. **problem-statement-structure.md** → Belongs in PRD template guidance and/or spec-reviewer. The discovered/whyItMatters/whatWasTried/constraints pattern.
3. **PRD_REFINE.md** (in prds/) → Battle-tested insights about: implementer trust balance, tentative language in examples, investigation vs implementation tasks, acceptance criteria quality, task sizing. Should be split between spec-reviewer, a new PRD authoring process doc, and possibly the PRD template.
4. **frameworks-research.md** → Anti-patterns section could become a framework process doc about "what not to do." Currently only in CLAUDE.md.
5. **design-philosophy.md** → Core "what this framework IS and ISN'T" — could be part of the seed or a framework README.

## What NOT to Integrate Yet

- draft-tasks-pattern.md — design unsettled (PRD 003/005 investigation)
- two-modes.md — design unsettled (PRD 004/005)
- principle-adherence-risks.md — more useful as project context than framework content
