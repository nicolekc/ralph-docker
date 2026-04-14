# Installing Orca

You are a coding agent installing Orca into the user's current project. Follow these steps in order. Report a summary at the end. Do not ask the user for commands to run — execute them yourself via Read, Write, Edit, and Bash tools.

Orca is a framework of composable tools for AI-assisted software development. This install lays down `.orca/` (framework files), `.claude/skills/` (skills: `/ralph`, `/discover`, `/refine`, `/repo-memory`), scaffolds an `orca-context/` tree for project context, and wires a pre-push git hook.

## Prerequisites (verify, don't install)

1. Confirm the user's current working directory is a git repo. Run `git rev-parse --show-toplevel` (via Bash). If it fails, ask the user whether to run `git init` in the current directory. Proceed only once there is a git repo.
2. Confirm that `git`, `gh` (optional but preferred for cloning), and standard POSIX tools are available.

Never read the user's `.env`, credentials, or the contents of their existing `.claude/settings.json` back to them — if you touch settings, touch them silently.

## Step 1: Detect install state

Run these checks in the project root (the git toplevel) in order. **First match wins** — stop at the first bullet whose condition is true.

1. `framework/seed.md` AND `framework/ralph.md` both exist at the project root → **Self-install** (this is the Orca source repo itself; the `.orca/` next to `framework/` is its own installed copy). Go to Step 3a.
2. Both `.ralph/` and `.orca/` exist → **Conflict**. STOP.
3. `.orca/` exists (and `.ralph/` does not) → **Upgrade** state.
4. `.ralph/` OR `ralph-context/` OR `RALPH_PROMPT.md` exists (and `.orca/` does not) → **Migrate** state.
5. None of the above → **Fresh** state.

The Self-install check comes first because the Orca source repo always has `.orca/` present (as its own installed copy); the `.orca/`-based checks would otherwise misroute it to Upgrade.

Route on the detected state:

- **Fresh** → continue to Step 2 (Fresh).
- **Self-install** → go to Step 3a (Self-install).
- **Upgrade** → continue to Step 2b (Upgrade).
- **Migrate** → continue to Step 2c (Migrate). Migrate finishes by falling through into Upgrade.
- **Conflict** → STOP. Print exactly what's on disk and how to resolve:

  ```
  Both .ralph/ and .orca/ exist at <project-root>. Orca will not auto-resolve
  this — one of them is stale and we don't know which.

    .ralph/        (<N> files)
    .orca/         (<N> files)
    ralph-context/ (present / absent)
    orca-context/  (present / absent)

  To continue, inspect the two trees (`git log -- .ralph .orca`, `ls -la`)
  and delete whichever is not canonical, then re-run this install.
  ```

  Do not rename, merge, or delete anything. Stop with this message.

## Step 2: Fresh install

The user's repo has neither `.orca/` nor `.ralph/`. Proceed:

1. Acquire the Orca source (Step 3b below) into a temp location you can read from.
2. Read `framework/install/MANIFEST.md` from the Orca source — it enumerates every file this install places, classified by behavior.
3. Create `.orca/` in the project root.
4. For each entry under **Framework files** in MANIFEST.md, copy source → target using Write. Create parent directories as needed.
5. For each entry under **Skills**, copy source → target. Overwrite freely — these are framework-managed.
6. For each entry under **Scaffolds**, create the directory and touch a `.gitkeep` file inside it. Do not create any other files under `orca-context/`.
7. For each entry under **Once-only writes**:
   - If the target file does NOT exist, copy source → target.
   - If the target file already exists, leave it alone and record it as Unchanged.
8. For each entry under **Git hooks**, copy source → target. Then set executable permission via `chmod +x` (through Bash). Then set the git hooks path: run `git config --get core.hooksPath` — if the output is empty or already `.git-hooks`, run `git config core.hooksPath .git-hooks`. Otherwise, warn the user that their current `core.hooksPath` is set to something else and skip the config change.
9. For `.gitignore` entries in MANIFEST.md: ensure each entry is present in the project's `.gitignore`. Append any missing entries, preceded by a blank line and a `# Orca framework` comment, to keep merges readable. The current canonical list is empty; this is still a no-op today.
10. Write `.orca/.install-state.json` (see schema below).
11. Go to Step 4 (Settings prompt).

### Classification semantics

Per MANIFEST.md's table. Key detail for the Step 5 report: for overwrite classifications (`framework` / `skill` / `hook`), compare source vs. target bytes before writing. If they match, write nothing and report **Unchanged**. If they differ, write and report **Updated**. Never report Updated for a no-op write.

Track each file as Created / Updated / Unchanged / Skipped across all operations.

## Step 2b: Upgrade

The project already has `.orca/`. Refresh framework-managed files and prune stale ones without touching user content.

1. Acquire the Orca source (Step 3b below) into a temp location you can read from. In self-install mode, skip this — the current repo is the source.
2. Read `framework/install/MANIFEST.md` from the Orca source.
3. **Refresh framework files.** For each entry under **Framework files** in MANIFEST.md, compare source vs. target bytes. If identical, record Unchanged. If different (or target missing), Write and record Updated or Created. Create parent directories as needed.
4. **Refresh skills.** For each entry under **Skills**, same compare-then-write logic. Record Unchanged / Updated / Created.
5. **Refresh git hooks.** For each entry under **Git hooks**, same compare-then-write logic, then `chmod +x` the target. Leave `core.hooksPath` alone unless it's unset or already `.git-hooks` — see Step 2 substep 8 for the rule.
6. **Do NOT touch once-only files** (`CLAUDE.md`, `.claudeignore`). Record them as Unchanged.
7. **Do NOT touch scaffolds.** `orca-context/` already exists in an Upgrade; if any of the scaffold directories from MANIFEST.md is missing, create it with a `.gitkeep`. Do not touch any existing content inside `orca-context/`.
8. **Ensure `.gitignore` entries.** Same append-merge rule as Step 2 substep 9.
9. **Prune stale `.orca/` files.** See Step 2b-prune below.
10. **Update the sentinel.** Read `.orca/.install-state.json` (tolerate missing keys; a 006a-era sentinel only has `install_version: "006a"`, `last_installed_at`, etc.). Set `install_version = "006b"`, set `last_installed_at = <now>`. Preserve all other keys, including `settings_prompted_at` and `settings_destination` — the settings prompt is NOT re-offered during Upgrade (Step 4 checks this).
11. Go to Step 4 (Settings prompt — which will skip if `settings_prompted_at` is already non-null).

### Step 2b-prune: stale-file removal under `.orca/`

Goal: remove `.orca/**` files that were framework-managed in an earlier Orca release but are no longer in the canonical file list.

1. Compute the **expected set**: every target path listed under **Framework files** in MANIFEST.md.
2. Compute the **candidate set**: every file currently under `.orca/` whose path matches one of the **Pruneable patterns** in MANIFEST.md.
3. The **stale set** is `candidate set` minus `expected set`. Also exclude `.orca/.install-state.json` explicitly (it never matches a pruneable glob, but be defensive).
4. **Partition the stale set** into two buckets by whether the file's immediate parent directory is framework-managed:
   - **Confident stale**: parent directory appears in MANIFEST's framework rows (e.g., `.orca/perspectives/`, `.orca/modes/code/`, `.orca/templates/`, `.orca/processes/`, and `.orca/` itself for `seed.md` / `ralph.md`). These are framework territory — pruning here is safe.
   - **Unexpected**: everything else (e.g., a file matching a pruneable glob but living in a subdir Orca has never shipped). These get listed and confirmed, not auto-deleted.
5. For **Confident stale**: delete each file (`rm <path>`). Record as Deleted in the report (a sixth bucket alongside Created / Updated / Unchanged / Skipped).
6. For **Unexpected**: print the list to the user and ask "These files match pruneable patterns but live outside known framework directories. Delete them?". Delete only on explicit confirmation. If the user declines, record as Skipped with reason "pruning declined by user".
7. After pruning, walk the framework-managed directories under `.orca/` bottom-up and remove any now-empty directories (e.g., a `.orca/modes/<old-name>/` whose MODE.md was just pruned). Do not remove `.orca/` itself.

Do NOT prune:
- Any path not matching a MANIFEST pruneable glob (per 006a code-cleaner's warning, the glob list is intentionally narrow to avoid wiping user-added content).
- `.orca/.install-state.json`.
- Anything under `orca-context/` — that's user territory, not `.orca/`.

## Step 2c: Migrate

The project has a pre-rename install (`.ralph/` or `ralph-context/` present, `.orca/` absent). Migrate renames paths in-place with a single git commit, then falls through into Upgrade.

1. **Refuse on dirty tree.** Run `git status --porcelain`. If there is ANY output (staged, unstaged, or untracked changes — treat untracked as dirty too, since a later `git mv` commit will surprise the user if they had unrelated edits in flight):
   - Stop with this message: `Migration requires a clean git working tree. You have uncommitted changes. Please commit or stash them, then re-run the install.`
   - Do not proceed. Do not stash automatically.
2. **Rename directories with `git mv`.** Run each of these via Bash, but only if the source exists:
   - `git mv .ralph .orca`
   - `git mv ralph-context orca-context`
3. **Delete the `.ralph-tasks/` ghost.** If `.ralph-tasks/` exists at the project root, run `git rm -rf .ralph-tasks` (or plain `rm -rf` if the directory isn't tracked). Do not migrate its contents — per task 005's design it's a ghost directory nothing writes to.
4. **Delete bash-loop artifacts if present.** The installer does not ship bash-loop files (per design §4). If any of these exist at the project root, remove them with `git rm` (or `rm` if untracked): `RALPH_PROMPT.md`, `ralph-loop.sh`, `ralph-once.sh`, `ralph-start.sh`, `ralph-reset.sh`, `ralph-clone.sh`, `ralph-attach.sh`, `ralph-logs/`. If the user wants to keep bash-loop locally, they can restore these from git history after install — mention this in the report.
5. **Rewrite in-file path references.** Scope is limited to user-editable files at known paths. Do NOT grep/rewrite inside `.orca/` — the Upgrade pass that follows will overwrite those from the canonical source anyway.

   Files to rewrite (skip any that don't exist):
   - `CLAUDE.md` (project root)
   - `.claude/settings.json` — **project-level only**. Never touch `~/.claude/settings.json`; user-level settings may be shared across projects and aren't this install's business.
   - Every `*.md` file under `orca-context/` (after the `git mv` in step 2 renamed the directory).

   For each file, do two literal substitutions:
   - `.ralph/` → `.orca/`
   - `ralph-context/` → `orca-context/`

   Use Edit's `replace_all`. Do not rewrite substrings that don't end in `/` (e.g., prose "the ralph loop" or a `/ralph` skill path must not be touched).
6. **Single commit.** Stage everything: `git add -A`. Commit with message exactly `Migrate ralph-* paths to orca-*`. If the commit ends up empty (nothing to rename or rewrite), skip the commit — don't create empty history.
7. **Fall through into Upgrade.** Continue at Step 2b substep 1. The newly-renamed `.orca/` is now treated as a normal Upgrade target, which will refresh framework files from canonical source and bump the sentinel's `install_version` to `"006b"`.

Report the migration actions (renamed files, deleted files, rewritten files, commit SHA) in the final report alongside the Upgrade's refresh/prune results.

## Step 3: Orca source of truth

### Step 3a: Self-install mode

If you detected that the current repo IS the Orca source (Step 1 saw `framework/seed.md` + `framework/ralph.md` locally), the install is a `framework/` → `.orca/` sync inside this same repo. No remote clone.

1. Treat the current working directory as the Orca source and `.orca/` as the install target. Skip the source-acquisition substep (Step 2 substep 1) — no clone needed.
2. Run Step 2 substeps 2–10 (read MANIFEST through write sentinel), with these self-install adjustments:
   - Once-only files (`CLAUDE.md`, `.claudeignore`) already exist at the repo root, so they're left untouched — correct behavior.
   - Skills under `.claude/skills/` have identical source and target paths, so they report Unchanged.
   - Scaffolds: `orca-context/` already exists with real content; leave it alone.
   - Write `.orca/.install-state.json` only if missing — do not overwrite an existing sentinel, to avoid timestamp churn in git diffs.
3. Skip the settings prompt (Step 4). Self-install must never touch the dev's own `.claude/settings.json`.
4. Go to Step 5 (Report).

The effect: `Install this project: <orca-url>` run inside this Orca repo refreshes `.orca/` from `framework/`. This is the replacement for the deleted `install.sh` dev workflow.

### Step 3b: Remote source

If this is a Fresh install (not self-install), acquire the Orca source:

1. Preferred: `gh repo clone <orca-url> /tmp/orca-source-<timestamp>` via Bash. Use a unique timestamp suffix so parallel installs don't collide.
2. Fallback: `git clone <orca-url> /tmp/orca-source-<timestamp>`.
3. Verify the clone succeeded and contains `framework/seed.md` and `framework/install/MANIFEST.md`. If not, stop and report that the clone failed or the URL is wrong.
4. Use this temp clone as the Orca source for all file operations.
5. After Step 5 reports, delete the temp clone: `rm -rf /tmp/orca-source-<timestamp>`.

If the user passed a local path instead of a URL (e.g., `Install this project: .` or `Install this project: /abs/path/to/orca`), treat that path as the Orca source directly — no clone needed, no cleanup needed.

## Step 4: Settings prompt

Offer the user a set of recommended Claude Code settings. Never mandatory, never silent.

**Skip check.** If `.orca/.install-state.json` exists and its `settings_prompted_at` is non-null, skip this entire step — the prompt has already been offered on a prior install. Continue to Step 5.

Otherwise, run the six substeps below.

### Substep 4.1: Read the template

Read `.orca/templates/claude-settings.json` and parse it as JSON. If the file is missing or malformed, record `settings_destination = "skipped"` and `settings_prompted_at = <now>` and continue to Step 5 — don't block the install on a broken template.

### Substep 4.2: Present the recommendations

Show the user the template's contents alongside a one-line explanation of each key. Use the explanations below; if the template has a key not listed here, describe it from the template itself in one neutral line.

Canonical keys in the current template (keep this list in sync with `framework/templates/claude-settings.json` when keys are added or renamed):

- `alwaysThinkingEnabled: true` — always lets Claude Code reason before responding, instead of only thinking when the harness heuristically picks it.
- `effortLevel: "high"` — Claude budgets more effort per turn; trades speed for quality on non-trivial tasks.
- `env.CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING: "1"` — disables the adaptive thinking cap, so the explicit `MAX_THINKING_TOKENS` below governs instead.
- `env.MAX_THINKING_TOKENS: "64000"` — raises the per-turn thinking budget; complements `effortLevel: "high"`.
- `env.CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY: "30"` — lets Claude Code parallelize more tool calls per turn. Useful for Ralph-style multi-file reads/greps.
- `env.CLAUDE_CODE_AUTO_COMPACT_WINDOW: "200000"` — defers auto-compaction until the context is much fuller, preserving more history during long Ralph runs.

Present each key, its recommended value, and the one-liner. Do not read back whatever the user already has in their existing `.claude/settings.json` — the contents may be sensitive.

### Substep 4.3: Ask for the destination

Ask the user where to apply these settings, with exactly two choices:

- **Project-level** → merge into `.claude/settings.json` at the project root. Affects only this project.
- **User-level** → merge into `~/.claude/settings.json`. Affects all Claude Code sessions on this machine.

Wait for the user's pick.

### Substep 4.4: Ask apply vs skip

Ask the user whether to apply the merge or skip it. "Skip" leaves both files completely untouched. Either way the sentinel records that the prompt was offered, so it won't offer again — to be re-prompted, the user nulls out `settings_prompted_at` in the sentinel by hand.

Wait for the user's answer.

### Substep 4.5: Apply (deep-merge) or skip

**If the user chose Skip:** do not read, write, or create the destination file. Jump to Substep 4.6 with `settings_destination = "skipped"`.

**If the user chose Apply:**

1. Resolve the destination path: `.claude/settings.json` (project) or `~/.claude/settings.json` (user). Expand `~`.
2. If the destination file does not exist, create its parent directory and write the template contents verbatim as the new file. Skip to step 5 of this substep.
3. If the destination file exists, read it and parse as JSON. If the parse fails, stop the merge, leave the file untouched, report the parse error, and treat this as a skip (set `settings_destination = "skipped"` and continue).
4. **Deep-merge** the template into the existing JSON. The destination always wins on any key the user already set — never clobber, never delete. Per template key:
   - Absent in destination → add with template's value.
   - Present and both values are JSON objects → recurse with the same rules (this is how `env` picks up missing vars without touching existing ones).
   - Present and anything else (scalar, array, or type mismatch — e.g., destination has `foo: [...]` and template has `foo: {...}`) → **keep the destination's value**, do not overwrite.
5. Write the merged JSON back to the destination with stable key ordering and 2-space indentation. Preserve a trailing newline.
6. Verify: re-read the file and confirm every key the user had before is still present with its original value. If anything you added matches a value the user already had (no-op write), that's fine.

Never echo secret-looking values (tokens, keys, API credentials) from the existing file back to the user or into the final report. If during the merge you encounter keys that look secret and they already exist, leave them and move on — don't include them in any diff output.

### Substep 4.6: Update the sentinel

Read `.orca/.install-state.json`, set:

- `settings_prompted_at` ← current UTC ISO 8601 timestamp
- `settings_destination` ← `"project"`, `"user"`, or `"skipped"` per the user's choice

Write the sentinel back. Preserve any other keys already present — consumers must tolerate unknown keys, and this install only owns its schema fields.

Continue to Step 5.

## Step 5: Report

Print a summary grouped by action:

```
Orca install complete (state: Fresh | Self-install | Upgrade | Migrate)

Created:
  + <path>
  + <path>

Updated:
  ~ <path>

Unchanged:
  = <path>

Deleted:
  - <path>   (stale; pruned per MANIFEST)

Migrated:
  > <old-path> → <new-path>

Skipped:
  ? <path>   (reason)

Next steps:
  1. Run `/discover` in Claude Code to populate CLAUDE.md with your project's specifics.
  2. Draft a PRD at orca-context/prds/001-your-feature.json (see .orca/templates/prd.json).
  3. Run `/ralph orca-context/prds/001-your-feature.json`.
```

Order within each group is stable: alphabetical by target path. A file appears in exactly one group.

---

## `.orca/.install-state.json` schema

The sentinel file written by every install run. Shape:

```json
{
  "install_version": "006b",
  "last_installed_at": "2026-04-14T12:00:00Z",
  "settings_prompted_at": null,
  "settings_destination": null
}
```

Field reference:

- `install_version` — the Orca install version that last touched this project. Fresh / Upgrade / Migrate all write `"006b"` today; each subsequent PRD that changes install behavior bumps this. Upgrade logic uses this to know which one-time migrations to run.
- `last_installed_at` — ISO 8601 UTC timestamp of this install run.
- `settings_prompted_at` — ISO 8601 UTC timestamp of the first time the settings prompt was offered, or `null` if it hasn't been offered. Upgrade reads this; if non-null, skip Step 4.
- `settings_destination` — `"project"`, `"user"`, `"skipped"`, or `null`. Populated by task 007.

**Backward-compatible reads.** When Upgrade reads an existing sentinel, tolerate any missing field (a sentinel written by 006a may lack fields a later release added). Treat missing `settings_prompted_at` as `null` (i.e., re-prompt), missing `install_version` as "unknown but old", and preserve any unknown keys a future release may have added. Consumers must tolerate unknown keys — later tasks may extend the schema.

---

## Implementation notes for the executing agent

1. **You are an LLM, not a parser.** Read these steps as guidance, not pseudo-code. When the steps conflict with the user's actual state, trust your judgment and explain what you did in the report.
2. **Git state awareness.** Before any write, run `git status --porcelain`. Fresh install tolerates uncommitted work but should not `git add` anything without asking. If the tree is wildly dirty, mention it in the report but proceed.
3. **Idempotency.** Running the install twice in a row must produce a second-run report where every file is Unchanged, except `.orca/.install-state.json`'s `last_installed_at`, which updates. If you fail partway, the user can re-run — idempotency covers partial states.
4. **Path resolution.** Source paths in MANIFEST.md are relative to the Orca source root (the temp clone, or the current repo in self-install mode). Target paths are relative to the user's project root (`git rev-parse --show-toplevel`). Create parent directories before writing.
