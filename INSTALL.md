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
- **Upgrade** → STOP with the message: `Upgrade path is implemented in task 006b. Not yet available.` (placeholder until 006b lands.)
- **Migrate** → STOP with the message: `Migrate path is implemented in task 006b. Not yet available.` (placeholder until 006b lands.)
- **Conflict** → STOP with the message: `Both .ralph/ and .orca/ are present. Reconcile manually before installing.` List the two paths for the user.

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

## Step 3: Orca source of truth

### Step 3a: Self-install mode

If you detected that the current repo IS the Orca source (Step 1 saw `framework/seed.md` + `framework/ralph.md` locally), the install is a `framework/` → `.orca/` sync inside this same repo. No remote clone.

1. Treat the current working directory as the Orca source and `.orca/` as the install target. Skip the source-acquisition substep (Step 2 substep 1) — no clone needed.
2. Run Step 2 substeps 2–10 (read MANIFEST through write sentinel), with these self-install adjustments:
   - Once-only files (`CLAUDE.md`, `.claudeignore`) already exist at the repo root, so they're left untouched — correct behavior.
   - Skills under `.claude/skills/` have identical source and target paths, so they report Unchanged.
   - Scaffolds: `orca-context/` already exists with real content; leave it alone.
   - Write `.orca/.install-state.json` only if missing — do not overwrite an existing sentinel, to avoid timestamp churn in git diffs.
3. Skip the settings prompt (Step 4). The dev already has their own `.claude/settings.json`.
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

## Step 4: Settings prompt (hook point — task 007 fills this in)

This is a no-op in the current install. Task 007 implements the body.

When task 007 lands, this step will:

1. Read the settings template from `.orca/templates/claude-settings.json` (task 007 moves it into place).
2. Show the user each key with a one-line explanation.
3. Ask: apply to the project (`.claude/settings.json`) or the user (`~/.claude/settings.json`)?
4. Ask: apply or skip?
5. If applying, deep-merge into the chosen destination, preserving existing keys and merging `env` per-key. Never clobber a user-set value.
6. Record the outcome in `.orca/.install-state.json`:
   - `settings_prompted_at` ← current UTC timestamp
   - `settings_destination` ← `"project"`, `"user"`, or `"skipped"`

For task 006a: do nothing in this step except leave `settings_prompted_at` and `settings_destination` as `null` in the sentinel file. On upgrade, if the sentinel shows a non-null `settings_prompted_at`, skip this step — the prompt has already been offered.

Never read raw secrets from `.claude/settings.json` back to the user or the report.

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
  "install_version": "006a",
  "last_installed_at": "2026-04-14T12:00:00Z",
  "settings_prompted_at": null,
  "settings_destination": null
}
```

Field reference:

- `install_version` — the Orca install version that last touched this project. Task 006a writes `"006a"`; 006b will bump it; each subsequent PRD that changes install behavior bumps it. Upgrade logic uses this to know which migrations to run.
- `last_installed_at` — ISO 8601 UTC timestamp of this install run.
- `settings_prompted_at` — ISO 8601 UTC timestamp of the first time the settings prompt was offered, or `null` if it hasn't been offered. Upgrade reads this; if non-null, skip Step 4.
- `settings_destination` — `"project"`, `"user"`, `"skipped"`, or `null`. Populated by task 007.

Consumers must tolerate unknown keys — later tasks may extend the schema.

---

## Implementation notes for the executing agent

1. **You are an LLM, not a parser.** Read these steps as guidance, not pseudo-code. When the steps conflict with the user's actual state, trust your judgment and explain what you did in the report.
2. **Git state awareness.** Before any write, run `git status --porcelain`. Fresh install tolerates uncommitted work but should not `git add` anything without asking. If the tree is wildly dirty, mention it in the report but proceed.
3. **Idempotency.** Running the install twice in a row must produce a second-run report where every file is Unchanged, except `.orca/.install-state.json`'s `last_installed_at`, which updates. If you fail partway, the user can re-run — idempotency covers partial states.
4. **Path resolution.** Source paths in MANIFEST.md are relative to the Orca source root (the temp clone, or the current repo in self-install mode). Target paths are relative to the user's project root (`git rev-parse --show-toplevel`). Create parent directories before writing.
