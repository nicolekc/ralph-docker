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

## Step 4: Settings prompt

Offer the user a set of recommended Claude Code settings. Never mandatory, never silent. Skipped at this step's entry check if the sentinel shows it's already been offered.

**Skip check.** If `.orca/.install-state.json` exists and its `settings_prompted_at` is non-null, skip this entire step — the prompt has already been offered on a prior install. Continue to Step 5.

Otherwise, run the six substeps below.

### Substep 4.1: Read the template

Read `.orca/templates/claude-settings.json` (you just wrote it in Step 2 from the framework source). Parse it as JSON. If the file is missing or malformed, record `settings_destination = "skipped"` and `settings_prompted_at = <now>` and continue to Step 5 — don't block the install on a broken template.

### Substep 4.2: Present the recommendations

Show the user the template's contents alongside a one-line explanation of each key. Use the explanations below; if the template has a key not listed here, describe it from the template itself in one neutral line.

Canonical keys in the current template:

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

Ask the user whether to apply the merge or skip it. "Skip" leaves both files completely untouched. The user can re-run the install later — but see the Skip check above: by default, the prompt won't offer again. If they want to be offered again later they can null out `settings_prompted_at` in the sentinel by hand.

Wait for the user's answer.

### Substep 4.5: Apply (deep-merge) or skip

**If the user chose Skip:** do not read, write, or create the destination file. Jump to Substep 4.6 with `settings_destination = "skipped"`.

**If the user chose Apply:**

1. Resolve the destination path: `.claude/settings.json` (project) or `~/.claude/settings.json` (user). Expand `~`.
2. If the destination file does not exist, create its parent directory and write the template contents verbatim as the new file. Skip to step 5 of this substep.
3. If the destination file exists, read it and parse as JSON. If the parse fails, stop the merge, leave the file untouched, report the parse error, and treat this as a skip (set `settings_destination = "skipped"` and continue).
4. **Deep-merge** the template into the existing JSON with these rules — the existing value always wins on any key the user has already set:
   - For each key in the template:
     - If the key is absent in the destination, add it with the template's value.
     - If the key is present and both values are JSON objects, recurse into the object with the same rules.
     - If the key is present and the types differ or the value is a scalar/array, **keep the destination's value** — do not overwrite.
   - Never delete a key that's in the destination but not the template.
   - For the `env` object specifically, merge per-key: add missing env vars, leave existing env vars alone.
5. Write the merged JSON back to the destination with stable key ordering and 2-space indentation. Preserve a trailing newline.
6. Verify: re-read the file and confirm every key the user had before is still present with its original value. If anything you added matches a value the user already had (no-op write), that's fine.

Never echo secret-looking values (tokens, keys, API credentials) from the existing file back to the user or into the final report. If during the merge you encounter keys that look secret and they already exist, leave them and move on — don't include them in any diff output.

### Substep 4.6: Update the sentinel

Read `.orca/.install-state.json`, set:

- `settings_prompted_at` ← current UTC ISO 8601 timestamp
- `settings_destination` ← `"project"`, `"user"`, or `"skipped"` per the user's choice

Write the sentinel back. Preserve any other keys already present — consumers must tolerate unknown keys, and this install only owns its schema fields.

Continue to Step 5.

### Summary of invariants

- The prompt is offered at most once per install lifetime (idempotent via the sentinel).
- Skip leaves no trace on disk except the sentinel update.
- Apply never clobbers any key the user has already set.
- The step never reads back the contents of the user's existing `.claude/settings.json` to the user or into the report.

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
