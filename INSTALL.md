# Installing Orca

You are a coding agent installing Orca into the user's current project. Follow these steps in order. Report a summary at the end. Do not ask the user for commands to run — execute them yourself via Read, Write, Edit, and Bash tools.

Orca is a framework of composable tools for AI-assisted software development. This install lays down `.orca/` (framework files), `.claude/skills/` (skills: `/ralph`, `/discover`, `/refine`, `/repo-memory`), scaffolds an `orca-context/` tree for project context, and wires a pre-push git hook.

## Prerequisites (verify, don't install)

1. Confirm the user's current working directory is a git repo. Run `git rev-parse --show-toplevel` (via Bash). If it fails, ask the user whether to run `git init` in the current directory. Proceed only once there is a git repo.
2. Confirm that `git`, `gh` (optional but preferred for cloning), and standard POSIX tools are available.

Never read the user's `.env`, credentials, or the contents of their existing `.claude/settings.json` back to them — if you touch settings, touch them silently.

## Step 1: Detect install state

Run these checks in the project root (the git toplevel) in order. **First match wins** — stop at the first bullet whose condition is true.

1. `framework/seed.md` AND `framework/ralph.md` both exist → **Self-install** (this is the Orca source repo itself; `.orca/` next to `framework/` is its own installed copy). This check comes first because the source repo always has `.orca/` present and would otherwise misroute to Upgrade.
2. Both `.ralph/` and `.orca/` exist → **Conflict**.
3. `.orca/` exists (and `.ralph/` does not) → **Upgrade**.
4. `.ralph/` OR `ralph-context/` OR `RALPH_PROMPT.md` exists (and `.orca/` does not) → **Migrate**.
5. None of the above → **Fresh**.

Route:

- **Fresh** → Step 2.
- **Self-install** → Step 3a, which delegates to Step 2b with self-install adjustments.
- **Upgrade** → Step 2b.
- **Migrate** → Step 2c, which falls through into Step 2b.
- **Conflict** → STOP with the message below. Do not rename, merge, or delete anything.

  ```
  Both .ralph/ and .orca/ exist at <project-root>. Orca will not auto-
  resolve this — one of them is stale and we don't know which.

    .ralph/        (<N> files)
    .orca/         (<N> files)
    ralph-context/ (present / absent)
    orca-context/  (present / absent)

  Inspect the two trees (e.g., `git log -- .ralph .orca`, `ls -la`) and
  delete whichever is not canonical, then re-run this install.
  ```

  Substitute `<project-root>` with the absolute path and `<N>` with actual file counts (`find .ralph -type f | wc -l`). Leave `(present / absent)` as a literal pair with the non-matching word struck; e.g., `ralph-context/ (present)`.

## Step 2: Fresh install

Neither `.orca/` nor `.ralph/` exists. Proceed:

1. Acquire the Orca source (Step 3b) into a readable temp location.
2. Read `framework/install/MANIFEST.md` from the source — it enumerates every file this install places, classified by behavior.
3. Create `.orca/` in the project root.
4. **Framework files**: copy source → target (Write). Create parents as needed.
5. **Skills**: copy source → target. Overwrite freely — framework-managed.
6. **Scaffolds**: create each directory with a `.gitkeep`. Do not create any other files under `orca-context/`.
7. **Once-only writes**: copy source → target only if the target does not exist. If it exists, leave it alone and record Unchanged.
8. **Git hooks**: copy, `chmod +x`, then `git config --get core.hooksPath` — if empty or already `.git-hooks`, run `git config core.hooksPath .git-hooks`. Otherwise, warn and skip the config change.
9. **`.gitignore` entries**: append missing entries (currently empty list — no-op today) preceded by a blank line and a `# Orca framework` comment.
10. Write `.orca/.install-state.json` (see schema below).
11. Go to Step 4 (Settings prompt).

### Classification semantics

For every overwrite classification (`framework` / `skill` / `hook`), compare source vs. target bytes before writing. Identical → no write, report **Unchanged**. Different (or target missing) → write, report **Updated** or **Created**. Never report Updated for a no-op write. Track each file as Created / Updated / Unchanged / Skipped.

## Step 2b: Upgrade

`.orca/` exists. Refresh framework-managed files and prune stale ones without touching user content.

1. Acquire the Orca source (Step 3b). In self-install mode, skip this — the current repo is the source.
2. Read `framework/install/MANIFEST.md` from the source.
3. **Refresh framework files**: compare-then-write per MANIFEST's Framework rows. Record Unchanged / Updated / Created.
4. **Refresh skills**: same compare-then-write for Skills rows.
5. **Refresh git hooks**: same compare-then-write, then `chmod +x`. `core.hooksPath` rule is the same as Step 2 substep 8 — leave it alone unless unset or already `.git-hooks`.
6. **Do NOT touch once-only files** (`CLAUDE.md`, `.claudeignore`). Record Unchanged.
7. **Scaffolds**: if any scaffold directory from MANIFEST is missing, create it with `.gitkeep`. Never touch existing content under `orca-context/`.
8. **Ensure `.gitignore` entries** (same append-merge as Step 2 substep 9).
9. **Prune stale `.orca/` files** (Step 2b-prune).
10. **Update the sentinel**: read `.orca/.install-state.json`, set `install_version = "006b"` and `last_installed_at = <now>`, preserve all other keys (including `settings_offered_at` and `settings_destination`). See the schema section for backward-compat read rules.
11. Go to Step 4 (which skips if `settings_offered_at` is already non-null — Upgrade never re-offers the prompt).

In self-install mode, steps 6, 7, 8, 10, and 11 are adjusted — see Step 3a.

### Step 2b-prune: stale-file removal under `.orca/`

Remove `.orca/**` files that were framework-managed in an earlier release but are no longer in the canonical list.

1. **Expected set**: every target under **Framework files** in MANIFEST.md.
2. **Candidate set**: every file currently under `.orca/` whose path matches a **Pruneable pattern** in MANIFEST.md.
3. **Stale set**: candidate minus expected. Exclude `.orca/.install-state.json` defensively (it shouldn't match any glob, but skip it unconditionally).
4. **Partition** by whether the immediate parent directory is framework-managed:
   - **Confident stale**: parent is a framework directory Orca has shipped (`.orca/` for `seed.md` / `ralph.md`, `.orca/perspectives/`, `.orca/modes/<mode>/` or deeper, `.orca/processes/`, `.orca/templates/`). Safe to auto-delete — users are told not to edit inside `.orca/`; anything here is either a prior-release framework file (stale) or a user file in framework territory (user's error, and the install is entitled to overwrite it anyway).
   - **Unexpected**: matches a pruneable glob but lives in a directory Orca has never shipped. List and confirm, don't auto-delete.
5. **Confident stale**: `rm <path>`. Record as **Deleted**.
6. **Unexpected**: print the list and ask "These files match pruneable patterns but live outside known framework directories. Delete them?". Delete on explicit confirmation only; otherwise record as **Skipped** with reason "pruning declined by user".
7. After pruning, walk framework-managed directories bottom-up and `rmdir` any now-empty ones (e.g., a `.orca/modes/<old-name>/` whose only child was just pruned). Do not remove `.orca/` itself.

Never prune:
- Paths not matching a MANIFEST pruneable glob (the glob list is intentionally narrow — see MANIFEST's note on not broadening it).
- `.orca/.install-state.json`.
- Anything under `orca-context/` — that's user territory.

## Step 2c: Migrate

Pre-rename install (`.ralph/` / `ralph-context/` / `RALPH_PROMPT.md` present, `.orca/` absent). Rename paths in-place with a single commit, then fall through into Upgrade.

1. **Refuse on dirty tree.** Run `git status --porcelain`. Any output at all — staged, unstaged, or untracked — means dirty. Stop with:
   ```
   Migration requires a clean git working tree. You have uncommitted
   changes. Please commit or stash them, then re-run the install.
   ```
   Do not stash automatically.
2. **Rename with `git mv`** (skip any whose source is absent):
   - `git mv .ralph .orca`
   - `git mv ralph-context orca-context`
3. **Delete the `.ralph-tasks/` ghost**: `git rm -rf .ralph-tasks` (or `rm -rf` if untracked). Don't migrate contents — per task 005 it's a ghost.
4. **Delete bash-loop artifacts if present.** The installer never ships these. If any exist at the project root, `git rm` them (or `rm` if untracked): `RALPH_PROMPT.md`, `ralph-loop.sh`, `ralph-once.sh`, `ralph-start.sh`, `ralph-reset.sh`, `ralph-clone.sh`, `ralph-attach.sh`, `ralph-logs/`. Mention in the report that the user can restore from git history if they still want bash-loop locally.
5. **Rewrite in-file path references.** Scope is user-editable files at known paths. Do NOT grep/rewrite inside `.orca/` — Upgrade will overwrite those.

   Files to rewrite (skip any that don't exist):
   - `CLAUDE.md` (project root)
   - `.claude/settings.json` — **project-level only**. Never touch `~/.claude/settings.json`.
   - Every `*.md` file under `orca-context/` (after the step-2 rename).

   For each file, do exactly these two literal substitutions with Edit's `replace_all`:
   - `.ralph/` → `.orca/`
   - `ralph-context/` → `orca-context/`

   The trailing `/` is load-bearing. Anything else stays untouched — in particular: prose mentions ("the ralph loop", "ralph framework"), the `/ralph` skill path, the `ralph.md` filename, git URLs containing "ralph", and any other substring that doesn't end in `/`. Do not add regex substitutions; the two literal strings above are the full set.
6. **Single commit.** `git add -A`, then commit with message exactly `Migrate ralph-* paths to orca-*`. If the result would be empty, skip the commit.
7. **Fall through into Upgrade** at Step 2b substep 1. Report migration actions (renamed, deleted, rewritten, commit SHA) alongside Upgrade's refresh/prune results.

## Step 3: Orca source of truth

### Step 3a: Self-install mode

The current repo IS the Orca source (Step 1 saw `framework/seed.md` + `framework/ralph.md` locally). The install is a `framework/` → `.orca/` sync inside this same repo. No remote clone.

Run Step 2b (Upgrade), treating the current working directory as the source and `.orca/` as the target, with these adjustments:

- **Substep 1 (source acquisition)**: skip — current repo is the source.
- **Skills refresh (substep 4)**: source and target paths are identical under `.claude/skills/`, so every file reports Unchanged. Still run the compare to be sure.
- **Once-only files (substep 6)**: `CLAUDE.md` and `.claudeignore` already exist at the repo root — leave them, same as Upgrade.
- **Scaffolds (substep 7)**: `orca-context/` already exists with real content — skip the `.gitkeep` step.
- **Prune (substep 9)**: run it. This is the point of routing self-install through Upgrade — stale `.orca/` files get cleaned up on self-install too.
- **Sentinel (substep 10)**: write `.orca/.install-state.json` only if missing. Do not overwrite an existing sentinel — avoids timestamp churn in git diffs on every developer sync.
- **Settings prompt (substep 11 / Step 4)**: skip entirely. Self-install must never touch the developer's own `.claude/settings.json`.

Then go to Step 5. Self-install replaces the deleted `install.sh` dev workflow: run from inside the Orca repo and it syncs `framework/` → `.orca/` plus prunes stale files.

### Step 3b: Remote source

For a Fresh or Upgrade install on someone else's project, acquire the Orca source:

1. Preferred: `gh repo clone <orca-url> /tmp/orca-source-<timestamp>` (unique suffix so parallel installs don't collide).
2. Fallback: `git clone <orca-url> /tmp/orca-source-<timestamp>`.
3. Verify the clone contains `framework/seed.md` and `framework/install/MANIFEST.md`. If not, stop and report.
4. Use this clone as the Orca source for all file operations.
5. After Step 5 reports, `rm -rf /tmp/orca-source-<timestamp>`.

If the user passed a local path (e.g., `Install this project: .` or `/abs/path/to/orca`), treat it as the source directly — no clone, no cleanup.

## Step 4: Settings prompt

Offer the user a set of recommended Claude Code settings. Never mandatory, never silent.

**Skip check.** If `.orca/.install-state.json` exists and its `settings_offered_at` is non-null, skip this entire step — the prompt has already been offered on a prior install. Continue to Step 5.

Otherwise, run the six substeps below.

### Substep 4.1: Read the template

Read `.orca/templates/claude-settings.json` and parse it as JSON. If the file is missing or malformed, record `settings_destination = "skipped"` and `settings_offered_at = <now>` and continue to Step 5 — don't block the install on a broken template.

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

Ask the user whether to apply the merge or skip it. "Skip" leaves both files completely untouched. Either way the sentinel records that the prompt was offered, so it won't offer again — to be re-prompted, the user nulls out `settings_offered_at` in the sentinel by hand.

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

- `settings_offered_at` ← current UTC ISO 8601 timestamp
- `settings_destination` ← `"project"`, `"user"`, or `"skipped"` per the user's choice

Write the sentinel back. Preserve any other keys already present — consumers must tolerate unknown keys, and this install only owns its schema fields.

Continue to Step 5.

## Step 5: Report

Print a summary grouped by action. Every file lands in exactly one bucket:

- **Created** — target didn't exist before; we wrote it.
- **Updated** — target existed and differed from source; we overwrote it.
- **Unchanged** — target existed and already matched source (compare passed), or it's a once-only target that was already present and we left it alone.
- **Deleted** — stale framework file pruned per MANIFEST.
- **Migrated** — renamed during Step 2c (`.ralph` → `.orca`, etc.) or deleted during Step 2c (ghost dirs, bash-loop artifacts). Report old path and new path (or "deleted").
- **Skipped** — action deliberately declined: `core.hooksPath` already points elsewhere, unexpected-prune rejected by user, settings destination chose Skip, etc. Always include a reason.

Order within each group is alphabetical by target path.

```
Orca install complete (state: Fresh | Self-install | Upgrade | Migrate)

Created:
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
  ? <path>   (<reason>)

Next steps:
  1. Run `/discover` in Claude Code to populate CLAUDE.md with your project's specifics.
  2. Draft a PRD at orca-context/prds/001-your-feature.json (see .orca/templates/prd.json).
  3. Run `/ralph orca-context/prds/001-your-feature.json`.
```

---

## `.orca/.install-state.json` schema

The sentinel file written by every install run. Shape:

```json
{
  "install_version": "006b",
  "last_installed_at": "2026-04-14T12:00:00Z",
  "settings_offered_at": null,
  "settings_destination": null
}
```

Field reference:

- `install_version` — Orca install version that last touched this project. Fresh / Upgrade / Migrate all write `"006b"` today; each future PRD that changes install behavior bumps this. Used to gate one-time migrations.
- `last_installed_at` — ISO 8601 UTC timestamp of this install run.
- `settings_offered_at` — ISO 8601 UTC timestamp of the first settings-prompt offer, or `null` if never offered. If non-null, Step 4 is skipped.
- `settings_destination` — `"project"`, `"user"`, `"skipped"`, or `null`. Populated by task 007.

**Backward-compatible reads.**

- **Sentinel absent entirely** (pre-006a state, should only happen on first Migrate or an install that predates the sentinel): treat every field as its default — `install_version = null`, `settings_offered_at = null`, `settings_destination = null`. Upgrade will then re-offer the settings prompt, which is correct for an install that never saw it.
- **Sentinel present but sparse** (written by an earlier release that had fewer fields, e.g., a 006a-era sentinel): tolerate any missing field with the same defaults above. Preserve every key you don't recognize — later releases may have added keys this version doesn't know, and consumers must tolerate unknowns.
- When writing, only set the fields you own this step. Don't delete or zero out keys you didn't touch.

---

## Implementation notes for the executing agent

1. **You are an LLM, not a parser.** Read these steps as guidance, not pseudo-code. When the steps conflict with the user's actual state, trust your judgment and explain what you did in the report.
2. **Git state awareness.** Before any write, run `git status --porcelain`. Fresh install tolerates uncommitted work but should not `git add` anything without asking. If the tree is wildly dirty, mention it in the report but proceed.
3. **Idempotency.** Running the install twice in a row must produce a second-run report where every file is Unchanged, except `.orca/.install-state.json`'s `last_installed_at`, which updates. If you fail partway, the user can re-run — idempotency covers partial states.
4. **Path resolution.** Source paths in MANIFEST.md are relative to the Orca source root (the temp clone, or the current repo in self-install mode). Target paths are relative to the user's project root (`git rev-parse --show-toplevel`). Create parent directories before writing.
