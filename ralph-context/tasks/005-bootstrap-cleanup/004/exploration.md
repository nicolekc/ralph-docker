# Documentation Audit: Task 004 Exploration

Audit of all documentation files against the current framework state. The bootstrap introduced perspectives (replacing roles), rewrote seed.md, added subagent dispatch to ralph.md, clarified the framework/installed boundary, and introduced the pipeline model in prd.md.

---

## 1. `docs/structure.md` — STALE (multiple issues)

### Issue 1: `.ralph/` directory listing shows `roles/` instead of `perspectives/` (line 15-19)

**Current text (line 11-24):**
```
.ralph/
  seed.md
  ralph.md
  roles/
    architect.md
    code-reviewer.md
    design-reviewer.md
    spec-reviewer.md
  processes/
    build-cycle.md
  templates/
    prd.json
```

**Actual `.ralph/` structure:**
```
.ralph/
  seed.md
  ralph.md
  perspectives/
    architect.md
    code-cleaner.md
    code-reviewer.md
    design-reviewer.md
    explorer.md
    planner.md
    spec-reviewer.md
  processes/
    build-cycle.md
    prd.md
  templates/
    prd.json
```

**Problems:**
- Line 15: `roles/` should be `perspectives/`
- Missing perspectives: `code-cleaner.md`, `explorer.md`, `planner.md`
- Missing process: `prd.md` (the pipeline process)

### Issue 2: `ralph-context/overrides/` still references `roles/` (line 33)

**Current text (line 33):**
```
    roles/                 # e.g., architect.md with project-specific context
```

**Should be:** `perspectives/` — though the actual `ralph-context/overrides/` directory on disk still has `roles/` too (this is itself a cleanup target for task 005).

### Issue 3: Missing `ralph-context/tasks/` in directory description (line 35-40)

The `ralph-context/` listing is mostly accurate but should mention `tasks/` more prominently in the tree — it's listed separately (line 44-53) but the initial tree (line 26-40) omits it from the main listing.

### Issue 4: `.ralph-tasks/` section (lines 61-83) — potentially stale

The doc describes `.ralph-tasks/` with `progress.txt` conventions, but in practice the framework now uses `ralph-context/tasks/<prd>/<task>/` for durable context, and `.ralph-tasks/` may not be actively used. The `progress.txt` conventions (lines 85-104) describe a per-task format, but the actual `progress.txt` in the repo root is a different file used by the bash loop runner (`RALPH_PROMPT.md` appends to it).

### Issue 5: AGENTS.md section (lines 117-121) — speculative

References AGENTS.md as a pattern. This is aspirational and no AGENTS.md files exist in the repo. Not strictly wrong, but describes something that isn't in use.

---

## 2. `docs/design-principles.md` — MOSTLY ACCURATE, minor issue

### Issue 1: P6 uses "roles" terminology (line 55)

**Line 55:** `Framework files (roles, processes, templates) are **copied** from the framework repo into a project.`

**Should say:** `Framework files (perspectives, processes, templates)` — roles have been replaced by perspectives.

### No other issues. The 11 principles are still current and accurately describe the framework design philosophy.

---

## 3. `docs/execution-strategies.md` — STALE (multiple issues)

### Issue 1: Subagent mode description is outdated (lines 9-12)

**Line 11:** `3. Ralph reads the PRD and orchestrates via the Task tool`
**Line 12:** `4. Each architect/implementer/reviewer is a subagent with clean context`

The current `ralph.md` describes dispatching subagents but doesn't mention "the Task tool" specifically. The roles listed should reference the current set (planner, architect, implementer, code-cleaner, design-reviewer, spec-reviewer, explorer).

### Issue 2: Setup line is outdated (line 16)

**Line 16:** `**Setup:** Install the framework to your project (copies `.ralph/` and `.claude/skills/ralph/`).`

The install process also copies `.claude/skills/discover/` and `.claude/skills/refine/`.

### Issue 3: Bash loop mode description is partly outdated (lines 22-25)

**Line 24:** `3. Each iteration reads RALPH_PROMPT.md and completes one task`

This is accurate for the bash-loop mode but doesn't reflect the bootstrap plan's intent to make RALPH_PROMPT.md a thin wrapper around ralph.md. Currently RALPH_PROMPT.md is still its own independent instruction set (uses `testsPassing` fields, references `progress.txt`), divergent from the subagent mode's ralph.md.

### Issue 4: Review loop description in comparison table (line 41)

**Line 41:** `| Review loop | Built-in (architect->implement->review) | Single pass per iteration |`

The subagent mode now uses the pipeline model from prd.md, which includes planner, explorer, design-reviewer, code-cleaner, and other perspectives beyond just architect->implement->review.

---

## 4. `CLAUDE.md` — MOSTLY ACCURATE, some issues

### Issue 1: Knowledge file references are all broken (lines 61-68)

All 8 knowledge files referenced in the "Key Knowledge Files" section do not exist at the paths listed:
- `ralph-context/knowledge/novel-verification-methods.md` — DOES NOT EXIST
- `ralph-context/knowledge/principle-adherence-risks.md` — DOES NOT EXIST
- `ralph-context/knowledge/success-criteria-format.md` — DOES NOT EXIST
- `ralph-context/knowledge/problem-statement-structure.md` — DOES NOT EXIST
- `ralph-context/knowledge/draft-tasks-pattern.md` — DOES NOT EXIST
- `ralph-context/knowledge/two-modes.md` — DOES NOT EXIST
- `ralph-context/knowledge/design-philosophy.md` — DOES NOT EXIST
- `ralph-context/knowledge/frameworks-research.md` — DOES NOT EXIST

The `ralph-context/knowledge/` directory contains only a `.gitkeep` file. These knowledge files exist only within their original task context directories (e.g., `ralph-context/tasks/000-prd-quality/001/novel-verification-methods.md`, `ralph-context/tasks/003-investigations/002/principle-adherence-risks.md`, etc.) but were never copied to the knowledge directory.

### Issue 2: "Over-classification of roles" anti-pattern (line 42)

**Line 42:** `- **Over-classification of roles**: 30 agent types creates a routing problem. Keep roles broad.`

The framework now uses "perspectives" not "roles" — though this sentence is specifically talking about anti-patterns in OTHER frameworks, so the word "roles" here refers to their concept, not Ralph's. Borderline, but could be confusing to a new reader given that Ralph explicitly moved away from "roles" to "perspectives."

### Otherwise accurate.

The "What This Repo Contains" section (lines 9-17) correctly lists `perspectives` in the framework description. The "Framework / Installed Boundary" (lines 19-23) correctly lists `perspectives/`. The structure is current.

---

## 5. `README.md` — SEVERELY STALE

This is the old "Ralph Technique" setup guide from before the bootstrap. It describes the pre-bootstrap workflow entirely.

### Issue 1: Entire framing is pre-bootstrap (throughout)

The README describes Ralph as a Docker-based bash loop workflow. The current framework also supports subagent mode (the primary mode post-bootstrap). The README makes no mention of perspectives, the pipeline model, seed.md, or the framework/installed boundary.

### Issue 2: Repository structure table (lines 38-52) is outdated

Lists files from the pre-bootstrap structure. Does not mention `framework/`, `.ralph/`, `ralph-context/`, perspectives, seed.md, or the PRD pipeline model.

### Issue 3: Install script references (lines 226-238) are pre-bootstrap

Describes `install.sh` copying `CLAUDE.md`, `RALPH_PROMPT.md`, `progress.txt`, `prds/`, `.claude/skills/`, etc. — the old flat structure. The bootstrap established `framework/` as the canonical source with `.ralph/` as the installed copy.

### Issue 4: PRD format references are pre-bootstrap (lines 404-408, 494, etc.)

References `testsPassing: false/true` field, which is the old PRD format. The current PRD format (as in `.ralph/templates/prd.json`) uses `status`, `pipeline`, `outcome`, and `verification` fields instead.

### Issue 5: Workflow descriptions are entirely bash-loop focused

No mention of the `/ralph` skill, subagent dispatch, the pipeline model, or perspectives. The entire guide assumes Docker + bash loop as the only execution method.

### Summary: README.md needs a complete rewrite to reflect the post-bootstrap framework.

---

## 6. `WHY.md` — PARTIALLY STALE

### Issue 1: "Roles" terminology in the tools table (line 62)

**Line 62:** `| Roles | Architect, reviewer, implementer — different *perspectives* on the same work |`

Ironically, the description already says "perspectives" but the tool name is "Roles." The framework now calls these "perspectives" explicitly.

### Issue 2: "Six independent tools" list (lines 58-66) is slightly outdated

The list references "Roles" as tool #2 and "The Orchestrator" as tool #6. These still conceptually exist but the naming and mechanism have evolved:
- "Roles" are now "Perspectives"
- "The Orchestrator" now uses a pipeline model with subagent dispatch, not just "enforces phases"
- "The PRD Format" has changed from `testsPassing` to `pipeline` + `status` + `outcome` + `verification`
- "The State System" description is still accurate
- "Knowledge Convention" is still accurate (though the knowledge directory itself is empty)
- "The Seed" description is still accurate

### Issue 3: Composability claim may be slightly misleading (lines 67-71)

"Want the Seed to improve any Claude session? Copy one file." — Still true.
"Want PRDs + roles without the orchestrator? Three files." — "roles" should be "perspectives."

### Otherwise the philosophical framing is still valid. The death spiral analysis, counterintuitive insight, and "what this is NOT" sections remain accurate.

---

## 7. `RALPH_PROMPT.md` — STALE (divergent from framework)

### Issue 1: Uses old PRD format (throughout)

References `testsPassing: false/true` throughout (lines 15, 20, 37, 42, 67). The current framework PRD format uses `status` and `pipeline` fields. This file is entirely divergent from the current `ralph.md` and `prd.md`.

### Issue 2: No awareness of pipeline model

Describes a flat task-completion model (find task with `testsPassing: false`, implement, set to true). Does not reference the pipeline model, perspectives, or role-based step processing.

### Issue 3: References `progress.txt` as the logging mechanism (lines 49-63)

The current framework uses `ralph-context/tasks/<prd>/<task>/` for durable context. The progress.txt convention described here is from the pre-bootstrap bash-loop workflow.

### Issue 4: Still references `<promise>COMPLETE</promise>` signal (lines 72-74)

This is a bash-loop specific mechanism. The bootstrap plan intended RALPH_PROMPT.md to become a thin wrapper around ralph.md (see plan.md line 75: `RALPH_PROMPT.md becomes thin wrapper: "Read .ralph/ralph.md. You are in bash-loop mode. PRD file is: [from script]."`)

### Summary: RALPH_PROMPT.md was identified for rewrite in the bootstrap plan but was not updated. It operates on a completely different mental model than the current framework.

---

## 8. `ralph-context/README.md` — SLIGHTLY STALE

### Issue 1: References `roles` in overrides (line 5)

**Line 5:** No explicit mention of roles, but the actual `overrides/` directory contains `overrides/roles/` instead of `overrides/perspectives/`. The README itself says "mirrors structure" which is accurate relative to whatever `.ralph/` contains — but since `.ralph/` now has `perspectives/`, the override directory structure is stale.

### Otherwise accurate. The four bullets accurately describe the purpose of each subdirectory.

---

## 9. Legacy files at repo root — NOT DOCS BUT RELEVANT

### `prds/PRD_TEMPLATE.json` — STALE

Uses old format with `sprint`, `acceptanceCriteria`, `testsPassing` fields. The current PRD format (`.ralph/templates/prd.json`) uses `name`, `description`, `signoff`, `tasks` with `outcome`, `verification`, `status`, `pipeline`.

### `prds/PRD_REFINE.md` — PARTIALLY STALE

References `testsPassing` in its guidelines (line 73 of `.claude/skills/refine/SKILL.md`).

### `.claude/skills/refine/SKILL.md` — STALE

Line 73: `Check that testsPassing: false for incomplete tasks and testsPassing: true for done tasks` — references old PRD format.

---

## 10. `framework/processes/build-cycle.md` — MOSTLY ACCURATE, minor drift

### Issue 1: References "reviewer" role (line 17)

**Line 17:** `3. **Reviewer** checks the implementation.`

The framework now has two review-type perspectives: `code-reviewer` (evaluates implementations) and `code-cleaner` (makes fixes directly). The build-cycle doesn't distinguish between them.

### Issue 2: Doesn't mention the pipeline model

This file describes the build cycle as a sequential flow but doesn't reference the pipeline model from `prd.md`. It's not wrong per se — it describes the conceptual flow — but there's overlap/tension with `prd.md` which describes the actual mechanism.

---

## 11. Internal consistency issues across `.ralph/` files

### Issue 1: `ralph.md` uses "Roles" heading and "roles" terminology (lines 10, 12, 14, 22)

The file heading is `## Roles` and text says "Active roles" and "Future roles." Since the framework moved from roles to perspectives, this file should use "perspectives" terminology or at minimum clarify the distinction.

### Issue 2: `prd.md` uses "role" in pipeline JSON (lines 11-14)

The pipeline array uses `"role"` as the field name: `{"role": "plan", "status": "complete"}`. All references throughout prd.md use "role" (line 7, 20, 28, 44, 53, 70). This is the mechanical field name in the JSON data structure, so renaming may or may not be desired, but it's inconsistent with the "perspectives" terminology.

### Issue 3: `planner.md` references `pipeline_completed` field (line 35)

**Line 35:** `Update pipeline_completed to include "plan".`

No PRD file in the repo uses a `pipeline_completed` field. The actual mechanism is setting the plan step's status to `"complete"` in the `pipeline` array. This instruction is either wrong or describes a field that was never implemented.

---

## Summary of Findings

| Document | Status | Severity |
|----------|--------|----------|
| `docs/structure.md` | STALE | High — shows wrong directory structure |
| `docs/design-principles.md` | MOSTLY ACCURATE | Low — one "roles" reference in P6 |
| `docs/execution-strategies.md` | STALE | Medium — outdated details, missing pipeline model |
| `CLAUDE.md` | MOSTLY ACCURATE | High — all 8 knowledge file references are broken |
| `README.md` | SEVERELY STALE | Critical — entire file describes pre-bootstrap workflow |
| `WHY.md` | PARTIALLY STALE | Low — "Roles" naming, otherwise philosophy is sound |
| `RALPH_PROMPT.md` | STALE | High — entirely divergent from current framework model |
| `ralph-context/README.md` | SLIGHTLY STALE | Low — accurate descriptions, stale override example |
| `framework/processes/build-cycle.md` | MOSTLY ACCURATE | Low — generic enough to still apply |
| `.ralph/ralph.md` | INCONSISTENT | Medium — uses "roles" terminology instead of "perspectives" |
| `.ralph/processes/prd.md` | INCONSISTENT | Low — uses "role" as JSON field name |
| `.ralph/perspectives/planner.md` | INCORRECT | Medium — references non-existent `pipeline_completed` field |
| `.claude/skills/refine/SKILL.md` | STALE | Medium — references old `testsPassing` PRD format |
| `prds/PRD_TEMPLATE.json` | STALE | High — old PRD format entirely |
| `ralph-context/overrides/roles/` | STALE | Low — directory should be `perspectives/` |
