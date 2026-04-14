# Task 002 — Implementer Verification

## Files touched

Created:
- `framework/modes/code/MODE.md` — full content per design §1.2.

Edited:
- `framework/templates/prd.json` — added `"mode": "code"` between `description` and `signoff`.
- `ralph-context/prds/006-modes-and-multisession.json` — added `"mode": "code"` at top level; marked task 002 `implementer` pipeline step `"complete"`.
- `docs/structure.md` — removed `build-cycle.md` from the `.ralph/processes/` ASCII listing.

Deleted:
- `framework/processes/build-cycle.md` — entire contents folded into `MODE.md`'s `## Build Cycle` section.

Not touched (per design §8.4): `framework/perspectives/**`, `framework/seed.md`, `framework/ralph.md`, `framework/processes/prd.md`, `.ralph/`, `framework/template.claude.settings.json`, any `ralph-context/tasks/` historical file.

## Content preservation (design §9.1 checklist)

- [x] **Green Builds** — verbatim from pre-aa7a43c `prd.md`, present in `## PRD Process Addendum → ### Green Builds`.
- [x] **Code Cleaning** — verbatim, present in `## PRD Process Addendum → ### Code Cleaning`.
- [x] **TDD sharpening of Implementer + QA Engineer** — present in `### TDD in the Verification Cascade` (blockquote for Implementer TDD, prose for QA "tests pass vs actually works").
- [x] **AGENTS.md paragraph** — verbatim from pre-aa7a43c `seed.md`, present in `## Seed Addendum → ### AGENTS.md`.
- [x] **Pipeline patterns** — all five patterns (standard, trivial, complex, high-level, investigation) present in `## Pipeline Patterns`, plus the "patterns, not a menu" sentence.
- [x] **code-cleaner ≠ qa-engineer distinction** — explicit paragraph under `## Perspectives` and cross-reference in `### code-cleaner vs qa-engineer`.
- [x] **`build-cycle.md`** — entire content (intro, `### The Cycle`, `### When to Skip Steps`, `### Parallel Tasks`, `### Redo`) present under `## Build Cycle`.
- [x] **Perspective registry** — all eight code-mode perspective files listed: architect, implementer, code-cleaner, code-reviewer, qa-engineer, design-reviewer, spec-reviewer, explorer. No planner or drafter (those are base).

Note on manifest §3a (atomic commits sharpening): per design §1.3 this was intentionally omitted — base already has the punchy phrasing restored in task 001, no duplicate needed. Manifest §3c likewise: TDD seed principle already lives in `framework/perspectives/implementer.md`; the Verification Cascade sharpening in MODE.md covers the flag for planners.

## Grep sweep

- `grep -rn "build-cycle" framework/` → **no matches.**
- `grep -rn "build-cycle" .claude/` → **no matches.**
- `grep -rn "build-cycle" docs/` → **no matches.**

Historical references remain in `ralph-context/tasks/` (task history, immutable) and in PRD 006 itself (task descriptions reference the historical filename). Per design §9.2, these are allowed.

## JSON validity

- `jq . framework/templates/prd.json` → OK. `mode` field sits between `description` and `signoff`.
- `jq . ralph-context/prds/006-modes-and-multisession.json` → OK. `mode` field sits between `description` and `signoff` at top level.

## Deviations from design

None. The design specified MODE.md content in §1.2 verbatim; it was copied verbatim (with connective prose left as-is). File layout, ordering, and wire-up match design §1.1, §4, §5, §8.
