# Task 006 — Easy Install: Architect Design

Scope note. The user has firmly rejected the plugin/marketplace path proposed by the explorer. The install mechanism is a plain chat message to Claude Code:

> Install this project: https://github.com/<owner>/orca

Everything below is designed to that constraint. The explorer's plugin analysis is not used; its install.sh analysis, three-state handling, and file inventory sections remain load-bearing inputs.

---

## 1. Install mechanism

### Chosen shape

Orca ships a **root-level `INSTALL.md`** that is written specifically for a coding agent to read top-to-bottom and execute. When a user types `Install this project: <url>` in Claude Code, Claude:

1. Reads `INSTALL.md` at the repo's root (via `gh api` or raw GitHub fetch; falls back to `git clone` into a temp dir if needed).
2. Follows its numbered steps in order. `INSTALL.md` is an executable runbook written in imperative prose: "do this, then that, using these tool calls." No shell command is required from the user.
3. Reports a summary at the end listing Created / Updated / Unchanged / Migrated / Skipped entries.

This is the entire bootstrap. There is no plugin, no marketplace, no curl-bash, no pre-existing skill needed. The user's Claude Code session alone is enough.

### Why an agent-native INSTALL.md (vs alternatives)

- **vs. AGENTS.md**: AGENTS.md is a project-context file ("how the agent should think about this repo"), not an install runbook. Polluting it with install steps conflates two things. We may still ship an AGENTS.md later for other purposes; task 006 doesn't need it.
- **vs. embedded install skill the repo tells Claude to copy first**: extra indirection. A skill is a file Claude reads for instructions. INSTALL.md *is* a file Claude reads for instructions. Installing a skill first just to read another file is a wasted hop.
- **vs. `llms.txt`**: `llms.txt` is for website-style content indexing — pointing LLMs at docs. Not designed as an executable runbook.
- **vs. README.md install section**: README is a human document with mixed audience and SEO/marketing text. An agent reading it has to filter. A dedicated INSTALL.md the agent reads verbatim is cleaner and cheaper.

### Shape of `INSTALL.md`

The file is ~100–150 lines, structured as:

```
# Installing Orca

You are a coding agent installing Orca into the user's current project.
Follow these steps in order. Report status at the end.

## Prerequisites (verify, don't install)
- User's working directory is a git repo (run `git rev-parse --show-toplevel`).
  If not, ask the user whether to `git init`. Proceed only if it's a repo.

## Step 1: Detect install state
Run these checks in the project root:
- Is `.orca/` present? → **Upgrade** state.
- Is `.ralph/` or `ralph-context/` present (and `.orca/` absent)? → **Migrate** state.
- Both `.ralph/` and `.orca/` present? → STOP. Report the conflict and ask the user.
- Neither present? → **Fresh** state.

## Step 2 (Fresh / Upgrade / Migrate)
(detailed sub-procedures for each, below)

## Step 3: Orca source of truth
Read the files to install from this repo. Two supported modes:
(a) You already have the repo cloned (local path). Use it directly.
(b) You do not. Run `gh repo clone <orca-url> /tmp/orca-<sha>` or equivalent,
    then use that. Delete the temp clone at the end.

## Step 4: File operations
... per-file table (see §4 inventory) ...

## Step 5: Settings template
(See §6 hook for task 007)

## Step 6: Report
Print a summary: Created / Updated / Unchanged / Migrated / Skipped.
```

The file is written in the same imperative voice as a good SKILL.md. It uses the same kind of "do X, report Y" cadence. Claude executes it via Read / Write / Edit / Bash tools.

### Embedded helpers

`INSTALL.md` references a small, supporting document at `framework/install/MANIFEST.md` (or similar) that enumerates:
- Canonical list of framework files (for overwrite-on-upgrade and stale-pruning).
- Classification of every file in the install scope (framework / user / scaffold / once-only).
- `.gitignore` entries to ensure.

Keeping the manifest separate from INSTALL.md keeps the runbook's prose stable across releases while the file list evolves.

---

## 2. Prior art from openclaw / similar

Survey findings (April 2026):

### `TechNickAI/openclaw-config` — closest match

This repo uses **exactly** the "user types `Set up X from <URL>`" pattern. Structure:
- Root-level `README.md` tells the user to say "Set up openclaw-config from https://github.com/TechNickAI/openclaw-config" to Claude Code.
- Root-level `AGENTS.md` holds project context for the agent.
- A pre-existing `openclaw` skill is what actually does the install. The project relies on that skill already being present.

**What we inherit**: the UX pattern (plain chat message with URL) and the separation between human-facing README and agent-facing doc.

**What we can't inherit**: they rely on a pre-existing skill to do the work. Orca has no such prerequisite — the user is installing Orca from zero. So we need the runbook itself (`INSTALL.md`) to stand in for the pre-existing skill, written for the agent to execute in-place.

### `win4r/OpenClaw-Skill`

README-based install instructions, manual `git clone` + `cp -r` steps. Designed for humans. Not an agent-executable runbook. Not a model to follow.

### `alirezarezvani/claude-skills`

Has `INSTALLATION.md` at the root, but it's a human-oriented multi-platform installation guide — bash commands, tables, troubleshooting. Not an agent runbook.

### `openai/codex` and the broader AGENTS.md ecosystem

AGENTS.md is gaining traction as a context file (≤150 lines, commands / testing / style / structure). Stewarded by the Agentic AI Foundation. Relevant **convention**: keep the agent-facing doc short, command-bearing, and at the repo root. Not relevant as an install mechanism — AGENTS.md is per-project context, not bootstrap.

### `llms.txt`

Website-level content index for LLMs. 844k+ sites adopted. Not an install runbook, so not directly applicable.

### Conclusion

**Nothing in the prior art exactly matches Orca's shape** (install from zero with no pre-existing skill, via a plain chat message). The closest analog is the TechNickAI pattern, but we are one step earlier in the chain because our user has no pre-existing Orca skill to drive the install. Our answer — an agent-executable `INSTALL.md` — is an adaptation, not a copy.

Implementers should know:
- The UX pattern (chat message with URL) **is** a real community convention as of April 2026.
- Making `INSTALL.md` the agent-readable runbook is a mild invention on top. It is consistent with how AGENTS.md and SKILL.md are written (imperative prose for agents), so it won't surprise anyone.

---

## 3. Install flow state machine

States and transitions, as executed by `INSTALL.md`:

```
              detect()
                |
      ┌─────────┼────────────┬────────────────┐
      ▼         ▼            ▼                ▼
    Fresh    Upgrade      Migrate           Conflict
    (none)  (.orca/ yes) (.ralph/ yes,     (both present)
                          .orca/ no)
      │         │            │                │
      │         │            │                ▼
      │         │            │             STOP + ask
      │         │            ▼
      │         │         git mv .ralph → .orca
      │         │         git mv ralph-context → orca-context
      │         │         delete .ralph-tasks if present (ghost)
      │         │         grep-replace ralph paths inside user files
      │         │         → falls through into Upgrade
      │         │            │
      │         └────────────┘
      ▼                      ▼
  install-fresh        upgrade-framework
  (all steps)          (framework files only;
                        skip user files)
      │                      │
      └──────────┬───────────┘
                 ▼
           prune stale .orca/ files
           (manifest-driven)
                 ▼
           settings prompt
           (idempotent; sentinel marker)
                 ▼
              report
```

### Fresh

Trigger: neither `.orca/` nor `.ralph/` present.

Steps:
1. Verify/offer `git init`.
2. Copy framework files to `.orca/` (framework-managed, overwrite semantics apply — but there's nothing to overwrite in Fresh).
3. Install skills to `.claude/skills/` (project-scoped; the user can commit them).
4. Scaffold `orca-context/{overrides,knowledge,prds,designs,tasks}/.gitkeep`.
5. Create `CLAUDE.md` from template (create-only).
6. Create `.claudeignore` from template (create-only — see §4 classification change from explorer's table).
7. Install `.git-hooks/pre-push`, `chmod +x`, set `core.hooksPath` if unset or already correct.
8. Merge `.gitignore` entries.
9. Settings prompt (§6).
10. Report.

### Upgrade

Trigger: `.orca/` exists.

Steps:
1. Refresh framework files under `.orca/` (overwrite if content differs, skip if identical).
2. Refresh skills under `.claude/skills/{ralph,discover,refine,repo-memory}/` (overwrite).
3. **Prune stale**: the manifest in `framework/install/MANIFEST.md` lists every canonical file under `.orca/`. Delete any file inside `.orca/` not in the manifest — but only files whose path matches the managed shape (`.orca/perspectives/*.md`, `.orca/modes/*/MODE.md`, etc.), with a report + confirm step for anything unexpected.
4. Do NOT touch `CLAUDE.md`, `.claudeignore` (once-only after first install), `orca-context/**`, user skills in `.claude/skills/` that aren't ours.
5. Ensure `.gitignore` entries present (append-merge).
6. Settings prompt is skipped if the sentinel (see §6) indicates it was already offered.
7. Report.

### Migrate

Trigger: `.ralph/` (or `ralph-context/`, or `RALPH_PROMPT.md`, or `ralph-*.sh`) present AND `.orca/` absent.

Steps:
1. Check `git status`. If dirty, stop and ask the user to commit or stash. (Recommend: stop, not stash automatically — stashing silent state is surprising.)
2. Perform `git mv`:
   - `.ralph` → `.orca`
   - `ralph-context` → `orca-context`
   - If bash-loop files present (`RALPH_PROMPT.md`, `ralph-loop.sh`, `ralph-once.sh`, `ralph-start.sh`, etc.) AND bash-loop mode is being kept: `git mv` them too. If not kept: delete them.
   - `.ralph-tasks/` → **delete**, not migrate (ghost dir; PRD confirmed).
   - `ralph-logs/` → delete if bash-loop not kept; rename if kept.
3. In-file reference rewrites (grep + write) across user files:
   - `.ralph/` → `.orca/`
   - `ralph-context/` → `orca-context/`
   - Scope: `CLAUDE.md`, `.claude/settings.json`, any `.md` under `orca-context/`. Do NOT rewrite files inside `.orca/` — those will be overwritten by the Upgrade pass that follows.
4. Commit the migration as a single commit: `Migrate ralph-* paths to orca-*`.
5. Fall through into Upgrade.

### Conflict (both `.ralph/` and `.orca/` present)

Stop. Print the two paths. Ask the user to reconcile manually. Do not attempt auto-merge.

---

## 4. File inventory and classification

This table is the spec for the manifest file (`framework/install/MANIFEST.md`) the installer reads. Derived from the explorer's §3 with explicit classification on every row.

### Framework files — overwrite on upgrade, prune if removed

| Source                                       | Target                                       |
|----------------------------------------------|----------------------------------------------|
| `framework/seed.md`                          | `.orca/seed.md`                              |
| `framework/ralph.md`                         | `.orca/ralph.md`                             |
| `framework/processes/prd.md`                 | `.orca/processes/prd.md`                     |
| `framework/perspectives/*.md` (all)          | `.orca/perspectives/*.md`                    |
| `framework/modes/*/MODE.md` (all)            | `.orca/modes/*/MODE.md`                      |
| `framework/templates/prd.json`               | `.orca/templates/prd.json`                   |
| `framework/templates/claude-settings.json` (post-task-007 location) | read at install time; not written to `.orca/` — used for the settings prompt |

The manifest is **authoritative**: pruning compares the actual `.orca/` tree against this list and deletes anything inside `.orca/` that isn't listed.

### Skill files — project-scoped, overwrite on upgrade

| Source                                          | Target                                          |
|-------------------------------------------------|-------------------------------------------------|
| `.claude/skills/ralph/SKILL.md`                 | `.claude/skills/ralph/SKILL.md`                 |
| `.claude/skills/discover/SKILL.md`              | `.claude/skills/discover/SKILL.md`              |
| `.claude/skills/refine/SKILL.md`                | `.claude/skills/refine/SKILL.md`                |
| `.claude/skills/repo-memory/SKILL.md`           | `.claude/skills/repo-memory/SKILL.md`           |
| `.claude/skills/repo-memory/references/*.md`    | `.claude/skills/repo-memory/references/*.md`    |

Skills are project-scoped (land in the user's repo at `.claude/skills/`) because the user rejected the plugin path. This matches the explorer's "project-scoped" alternative.

### Once-only writes — create if absent, never overwrite

| Source                               | Target                     | Notes                                |
|--------------------------------------|----------------------------|--------------------------------------|
| `templates/CLAUDE.md.template`       | `CLAUDE.md`                | User edits it; never clobber         |
| `templates/.claudeignore`            | `.claudeignore`            | Change from today's behavior (today's `install.sh` overwrites; we switch to create-only because users add project-specific entries — matches explorer §7 Q8) |

### Scaffolds — create directory and `.gitkeep` if absent

- `orca-context/overrides/.gitkeep`
- `orca-context/knowledge/.gitkeep`
- `orca-context/prds/.gitkeep`
- `orca-context/designs/.gitkeep`
- `orca-context/tasks/.gitkeep`

Do not touch any existing content inside `orca-context/`.

### Git hooks — framework-managed, chmod +x, config idempotent

| Source                               | Target                         |
|--------------------------------------|--------------------------------|
| `templates/.git-hooks/pre-push`      | `.git-hooks/pre-push` + chmod  |

Then: `git config core.hooksPath .git-hooks` — only set if current value is empty or already `.git-hooks`. If user has a different hooks path, warn and skip.

### `.gitignore` — append-merge

Append missing entries from the canonical list. Today's list is empty; the mechanism stays in place for future entries.

### Files that do NOT ship to user projects

Per explorer §3 and confirmed here:
- `framework/` itself (target gets `.orca/`, a derived copy).
- `docs/`, top-level `CLAUDE.md`, `BACKLOG.json`, `README.md`, `WHY.md`, `progress.txt`, this repo's `orca-context/`.
- Docker infra: `Dockerfile`, `orca-start.sh`, `orca-attach.sh`, `orca-clone.sh`, `orca-reset.sh`, `node_modules/`.
- `install.sh` (deleted anyway).

### Bash-loop files — decision for this task

The explorer flagged bash-loop's fate as an open question. **Decision**: the install flow does NOT copy bash-loop files (`orca-loop.sh`, `orca-once.sh`, `ORCA_PROMPT.md`, `orca-logs/`) into user projects. Rationale:

- Subagent mode is the default per PRD 005 and post-task-005 state.
- Bash-loop mode, if still used, is used *on this repo* for self-hosting, not pushed into downstream users' projects.
- Keeping those files out of the installer removes a branch, a prompt, and a migration edge case.

If bash-loop mode is later resurrected for downstream users, that's a new install option added to `INSTALL.md`; not in scope here.

### INSTALL.md itself

Ships in this repo's root. It is not copied to user projects — it's the runbook an agent reads to do the install into someone else's project. Same for `framework/install/MANIFEST.md` (consulted during install, not copied).

---

## 5. Self-hosting continuity

This repo's `.orca/` is a derived copy of `framework/`. After task 006 lands, self-hosting must still work.

### Self-install mode

`INSTALL.md` supports a "local source" mode, same as the explorer's open question #12. Behavior:

- If the current working directory contains both `framework/` and `.orca/` (i.e., this is the Orca repo itself), the install reads framework files from the local `framework/` directory instead of doing a git clone.
- Detection: check for the presence of `framework/seed.md` + `framework/ralph.md` + `.git` pointing at a remote whose URL contains `/orca`. If so, treat it as self-install.
- Effect: running `Install this project: https://github.com/<owner>/orca` *inside the Orca repo* becomes an Upgrade that syncs `framework/` → `.orca/` — replacing what `install.sh` does today for the dev workflow.

### First self-upgrade post-task-006

When task 006 ships, this repo is already in Upgrade state (`.orca/` exists). Running the new install against itself should:
- Detect Upgrade.
- Detect self-install (local source).
- Refresh `.orca/` from `framework/`.
- Prune any stale `.orca/` files (e.g., if this PRD removed any).
- Skip the settings prompt (developer's settings are already set).
- Report.

This is the acceptance path: the self-host's own first-ever run of the new install flow must be a clean no-op-or-near-no-op.

### install.sh deletion is safe

Because self-install mode is covered, deleting `install.sh` doesn't strand the dev workflow. The dev workflow becomes: inside Claude Code, from this repo, type `Install this project: .` (or the self-repo URL); Claude reads `INSTALL.md`, takes the self-install branch, syncs framework → `.orca/`.

---

## 6. Hook for task 007 settings

Task 007's job is (a) moving the settings template to `framework/templates/` and (b) wiring install to offer it. Task 006 provides the hook point.

### Hook contract

Inside `INSTALL.md` Step 5 (Settings prompt), there is a sub-section labeled `Settings template` with this behavior, which task 007 fills in:

1. **Read** the settings template from `.orca/templates/claude-settings.json` (post-task-007 location).
2. **Show** the keys and a one-line explanation per key. (Copy drafted in task 007.)
3. **Ask** destination: project (`.claude/settings.json`) or user (`~/.claude/settings.json`).
4. **Ask** apply or skip. Never silent.
5. **Deep-merge** if applying. Preserve existing keys. Merge `env` per-key.
6. **Sentinel**: record the prompt outcome so upgrades don't re-ask. Sentinel lives in `.orca/.install-state.json`:

   ```json
   {
     "settings_prompted_at": "2026-04-14T12:00:00Z",
     "settings_destination": "project|user|skipped"
   }
   ```

   Upgrade reads this file; if present, skip the prompt. If the user wants to re-offer, they delete or edit the sentinel manually. (Or a future `/orca-settings` skill can re-drive it — not in this task's scope.)

### Why a separate sentinel file (not a key in `settings.json`)

Explorer §6 proposed either. A sentinel file under `.orca/` is cleaner:
- Doesn't pollute the user's `settings.json` with an Orca-specific key.
- Lives alongside other install state (room to grow: `.install-state.json` can hold version, migration history, future flags).
- Deleting `.orca/` also resets install state — matches user intent if they're starting over.

### Task 007 scope confirmed

Task 007 handles: (a) moving the template file, (b) filling in the copy/explanation for each setting in INSTALL.md Step 5, (c) implementing the deep-merge. Task 006 lands the hook point, the sentinel schema, and the skip-on-upgrade logic.

---

## 7. What replaces install.sh behavior

Per explorer §5, mapping old → new:

| install.sh behavior                          | Fate                                         |
|----------------------------------------------|----------------------------------------------|
| `copy_framework_file` / `copy_user_file`     | Kept as conceptual rules in INSTALL.md ("overwrite" vs "create-only") |
| Walk `framework/` and mirror to `.orca/`     | Kept; driven by MANIFEST.md                  |
| `orca-context/` scaffold with `.gitkeep`     | Kept                                         |
| Git hooks copy + chmod + core.hooksPath      | Kept, with conditional `core.hooksPath` set |
| `.gitignore` append-merge                    | Kept                                         |
| CREATED/UPDATED/UNCHANGED tracking + report  | Kept; report format documented in INSTALL.md |
| `--bash-loop` branch                         | **Dropped.** Bash-loop files don't ship.     |
| Argument parsing, `$1`, target-dir handling  | Dropped; Claude knows `cwd`                  |
| Hard-fail on missing `.git`                  | Replaced with "ask to `git init`"            |
| `find -path "*/roles" -prune`                | Dropped; dead code                           |
| "exclude roles/" carve-out                   | Dropped; dead code                           |
| Fresh-install-only semantics                 | **Replaced** with three-state detection      |
| No upgrade/migration                         | **Added**                                    |
| No stale-file pruning                        | **Added** via MANIFEST                       |
| No settings prompt                           | **Added** via task 007 hook                  |

The old `install.sh` is deleted by the implementer.

---

## 8. Task split decision

**Decision: split task 006 into 006a and 006b.**

Rationale:
- The Fresh install flow is self-contained and can ship independently. A user installing into a fresh repo gets value from 006a alone.
- The Upgrade + Migrate flows need MANIFEST pruning, git-mv migration, and in-file rewrites — a meaningfully different set of concerns.
- Self-install continuity depends on Upgrade being correct; if we land Fresh first, self-install is broken in the interim until 006b lands. Mitigation: land 006a and 006b back-to-back, but keep them separately reviewable so the implementer doesn't have to hold the full flow in head at once.
- PRD 006 task description explicitly grants authority to split.

The settings prompt lives in task 007 regardless; the hook for it is added in 006a.

### Task 006a definition

```
id: 006a
name: Install — fresh and self-install (INSTALL.md runbook)
dependencies: [005]
description:
  Create the install mechanism: a root-level INSTALL.md that Claude Code
  executes when a user types "Install this project: <url>". Scope this
  task to: (1) the INSTALL.md file itself, (2) a supporting
  framework/install/MANIFEST.md that enumerates the canonical file set,
  (3) the Fresh install path (no .orca/, no .ralph/), (4) self-install
  mode for this repo (sync framework/ → .orca/ from a local clone),
  (5) the .orca/.install-state.json sentinel schema and the hook point
  in INSTALL.md Step 5 for task 007's settings prompt (no-op in 006a;
  task 007 fills it in), (6) delete install.sh. See
  orca-context/tasks/006-modes-and-multisession/006/design.md §1, §3
  (Fresh branch), §4, §5, §6.
outcome:
  Typing "Install this project: <orca-url>" in a fresh git repo installs
  Orca completely in under 30 seconds, end-to-end, inside Claude Code,
  no shell commands. Running the same in this self-hosted repo performs
  a no-op-or-near-no-op Upgrade via self-install mode. install.sh is
  gone. INSTALL.md is the single source of install truth.
verification:
  Fresh install works. Self-install on this repo refreshes .orca/
  cleanly. install.sh is deleted and no reference to it remains in
  README / CLAUDE.md / docs (for docs updates themselves task 008 owns,
  but install.sh's own removal must leave no dangling invocations in
  code).
pipeline:
  - plan (inherit completed plan from 006)
  - architect (this file covers both 006a and 006b; mark as complete)
  - implementer
  - code-cleaner
```

### Task 006b definition

```
id: 006b
name: Install — upgrade, migrate, prune
dependencies: [006a]
description:
  Extend INSTALL.md with the Upgrade and Migrate branches of the state
  machine. Implement: (1) detection of .orca/ (Upgrade) vs .ralph/
  (Migrate) vs conflict vs Fresh; (2) Upgrade path that refreshes
  framework files and prunes stale files per MANIFEST.md; (3) Migrate
  path that performs git mv on .ralph → .orca, ralph-context → orca-
  context, deletes the .ralph-tasks/ ghost, and rewrites in-file path
  references in CLAUDE.md / settings.json / orca-context/**; (4)
  migration safety (dirty-tree refusal, single migration commit); (5)
  conflict handling when both .ralph/ and .orca/ exist. See
  orca-context/tasks/006-modes-and-multisession/006/design.md §3
  (Upgrade, Migrate, Conflict branches), §4 (pruning), §7.
outcome:
  Running the install against a pre-rename ralph-* project migrates it
  cleanly to orca-* paths with a single commit; running against an
  existing orca-* project upgrades it and prunes stale files without
  touching user content; running against a Fresh project (006a path)
  still works.
verification:
  Given a ralph-era test repo (copy of pre-rename state), install
  produces a clean orca-* tree. Given an up-to-date orca-* repo,
  install is a no-op. Given a repo with both .ralph/ and .orca/,
  install stops with a clear error. Self-install on this repo continues
  to work and prunes anything 006a missed.
pipeline:
  - plan (inherit completed plan from 006)
  - architect (this file covers both; mark as complete)
  - implementer
  - code-cleaner
```

### PRD JSON changes required

The architect will update the PRD to:
- Remove the original single task 006 in favor of 006a and 006b.
- Update task 007's dependency from `["006"]` → `["006a"]` (settings hook lands in 006a).
- Update task 008's dependency list `["001", ..., "006", "007"]` → `["001", ..., "006a", "006b", "007"]`.
- Mark plan and architect as complete for both 006a and 006b (the plan was done for the original 006; architect output is this single design covering both).

---

## 9. Implementer scope summary

### For 006a implementer

Write these files:
- `/workspace/INSTALL.md` — the runbook. ~100–150 lines. Imperative prose. Fresh branch and self-install mode fully described; Upgrade and Migrate branches marked "see 006b".
- `/workspace/framework/install/MANIFEST.md` — canonical file list. One section per classification (framework / skill / once-only / scaffold / hook / gitignore). Machine-readable enough that a future docs-generator could parse it.
- `/workspace/.orca/.install-state.json` schema documented in INSTALL.md (not created until first install runs).

Modify:
- Nothing in `framework/` except adding `framework/install/MANIFEST.md`.
- Nothing in `.orca/` directly (remember the framework/installed boundary).
- Self-install mode must eventually update `.orca/` from `framework/` — that's at install-run time, not at authoring time.

Delete:
- `/workspace/install.sh`.

Do NOT touch:
- `framework/template.claude.settings.json` — that move is task 007's. 006a references the future location (`.orca/templates/claude-settings.json`) in INSTALL.md's Step 5 placeholder. When task 007 moves the file, INSTALL.md's reference already matches; only the prompt body needs filling.

Do NOT scaffold:
- `.orca-tasks/` — ghost.
- `orca-logs/` — bash-loop not shipping.

### For 006b implementer

Extend:
- `INSTALL.md` Steps 1–2 to include Upgrade / Migrate / Conflict branches.
- `framework/install/MANIFEST.md` — add any fields needed for pruning (e.g., "pruneable pattern globs" per classification).

Implement:
- Detection logic in INSTALL.md prose.
- Migration git-mv operations.
- In-file reference rewrites, scope limited to listed user files.
- Stale-file pruning inside `.orca/` driven by MANIFEST.
- Dirty-tree refusal during Migrate.

Test matrix:
- Fresh (should still work end-to-end).
- Upgrade on current self-hosted repo.
- Migrate from a synthetic pre-rename repo.
- Conflict case — stop with clear error.

### Things the implementer(s) should watch for

1. **INSTALL.md is executed by an LLM, not a parser.** Write prose, not pseudo-code. Use imperative sentences. Trust the executor (design principle P2).
2. **Never read raw secrets during install.** If reading `.claude/settings.json` to deep-merge, don't print its contents back to the user or the report.
3. **Deep-merge semantics for settings** (006a/007 boundary): preserve unknown keys, merge `env` per-key, never overwrite a key the user already set to something non-default.
4. **Git state awareness**: Migrate should refuse on dirty trees; Fresh can tolerate uncommitted files but should not add anything to git index without the user's say-so. Use `git status --porcelain` to detect.
5. **Idempotency reporting**: the end-of-run summary must be accurate. Use content comparison (like `install.sh`'s `cmp -s` approach) to distinguish Updated from Unchanged.

---

## Appendix: Sources from prior-art survey

- TechNickAI/openclaw-config — `https://github.com/TechNickAI/openclaw-config` (closest UX analog; chat-driven install via pre-existing skill)
- win4r/OpenClaw-Skill — `https://github.com/win4r/OpenClaw-Skill` (README-based manual install; not a runbook)
- alirezarezvani/claude-skills/INSTALLATION.md — human-oriented multi-platform install guide
- agents.md / AGENTS.md spec — `https://agents.md/` and `https://github.com/agentsmd/agents.md` (context convention, not install)
- openai/codex AGENTS.md — `https://github.com/openai/codex/blob/main/AGENTS.md` (example AGENTS.md in a real project)
- llms.txt — website LLM content index, not an install mechanism
- Claude Code plugin marketplaces (rejected per user decision) — `https://code.claude.com/docs/en/plugin-marketplaces`
