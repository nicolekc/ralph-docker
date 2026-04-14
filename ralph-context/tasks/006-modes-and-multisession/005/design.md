# Task 005 Design: ralph → orca rename

Mechanical rename. No new abstractions. One cohesive commit so the repo is never in a half-renamed state and `/ralph` can keep executing the remaining PRD tasks right after the commit lands.

## 1. Execution Plan

Do it in this order inside a single commit. Each step isolates one class of change so the `git diff` is reviewable in passes.

**Step 0 — sanity:**
- `git status` clean before starting (aside from `.claude/settings.json` if that's intentional).
- Confirm you are on branch `ralph/006-modes-and-multisession`.

**Step 1 — directory moves (git mv only, no content edits yet):**
1. `git mv ralph-context orca-context`
2. `git mv .ralph .orca`
3. Delete `ralph-logs/` outright — it is bash-loop debris (see §4). Use `git rm -r ralph-logs` if tracked, else `rm -rf`. Verify with `git status`.
4. `rm -rf .ralph-tasks` if it exists (it does not in this tree, but the command is a no-op and safe).

At this point the tree is broken (code inside still references old paths) but the filesystem layout is right. Do not commit yet.

**Step 2 — script renames (git mv, no content edits yet):**
1. `git mv ralph-start.sh orca-start.sh`
2. `git mv ralph-loop.sh orca-loop.sh`
3. `git mv ralph-once.sh orca-once.sh`
4. `git mv ralph-reset.sh orca-reset.sh`
5. `git mv ralph-clone.sh orca-clone.sh`
6. `git mv ralph-attach.sh orca-attach.sh`
7. `git mv RALPH_PROMPT.md ORCA_PROMPT.md`

**Step 3 — canonical source edits in `framework/`:**
Every `.ralph/` path reference in `framework/` must become `.orca/`. These are the files `framework/seed.md`, `framework/ralph.md`, `framework/processes/prd.md`, `framework/perspectives/*.md`, `framework/modes/code/MODE.md`, `framework/templates/prd.json`.

Rule: change only the path-flavored strings. Keep the process prose ("Ralph reads the PRD", "Ralph dispatches", "you are operating as Ralph") alone. See §2 for the exact path tokens to substitute.

**Step 4 — infra script body edits:**
Inside each renamed `orca-*.sh`:
- Update banner comments and `# Usage:` lines (`ralph-start.sh` → `orca-start.sh`, etc.).
- `orca-start.sh`: change the default `CONTAINER_NAME="${2:-ralph-$FOLDER_NAME}"` → `orca-$FOLDER_NAME`. Change image tag `ralph-claude:latest` → `orca-claude:latest`. Update the "🚀 Ralph Container" label (this is path-flavored — it identifies the orca container, not the ralph process).
- `orca-clone.sh`: change `CONTAINER_NAME="ralph-${REPO_NAME}..."` and `VOLUME_NAME="ralph-vol-${REPO_NAME}..."` → `orca-*`. Image tag → `orca-claude:latest`.
- `orca-attach.sh`: update docker filter `name=ralph-` → `name=orca-`.
- `orca-reset.sh`: update grep pattern and help text (`^ralph-` → `^orca-`, `ralph-start.sh` → `orca-start.sh`, `docker volume rm ralph-vol-...` → `orca-vol-...`).
- `orca-loop.sh` / `orca-once.sh`: default `PROMPT_FILE="${3:-RALPH_PROMPT.md}"` → `ORCA_PROMPT.md`. The `mkdir -p ralph-logs` and log-path strings: delete the logging block entirely since `ralph-logs/` is going away (see §4). Keep the iteration loop, just drop the log file plumbing.

**Step 5 — `ORCA_PROMPT.md`:**
Rename is already done by git mv. Inside: change `.ralph/ralph.md` → `.orca/ralph.md`. Keep "Ralph operating in bash-loop mode" process prose.

**Step 6 — Dockerfile:**
No `ralph-claude` literal appears inside `Dockerfile` itself (tag is applied at build time). No edit needed unless a comment mentions the tag — grep to confirm. The image is built with `docker build -t orca-claude:latest .` now; document this in README.

**Step 7 — Top-level docs / config:**
- `CLAUDE.md` — see §3.
- `README.md` — see §3.
- `.gitignore` — `/ralph-logs/` line goes away entirely.
- `docs/structure.md` — see §3.
- `docs/execution-strategies.md` — see §3.
- `templates/CLAUDE.md.template` — `.ralph/seed.md` → `.orca/seed.md`.
- `templates/.claudeignore` — `ralph-logs` block goes away (same as .gitignore).

**Step 8 — skills:**
- `.claude/skills/ralph/SKILL.md` — change `.ralph/ralph.md` → `.orca/ralph.md`. The skill name stays `ralph` (user-stated).
- `.claude/skills/refine/SKILL.md` — `ralph-context/prds/...` example → `orca-context/prds/...`.
- `.claude/skills/discover/SKILL.md` — grep and fix if any paths appear.

**Step 9 — `install.sh`:**
Minimal touch. This file gets deleted in task 006 (PRD says so explicitly). Touch only what's needed so the file's internal references aren't lying to a reader who opens it before task 006 lands:
- Header comment `Ralph Framework Installer` → fine as-is (process prose).
- The `RALPH_DIR` variable and installer internals reference `.ralph/`, `ralph-context/`, `.ralph-tasks/`, `ralph-logs/`, `RALPH_PROMPT.md`, `ralph-loop.sh`, `ralph-once.sh`.
- Update the path strings inside: `.ralph` → `.orca`, `ralph-context` → `orca-context`, `RALPH_PROMPT.md` → `ORCA_PROMPT.md`, `ralph-loop.sh` → `orca-loop.sh`, `ralph-once.sh` → `orca-once.sh`.
- Remove the two `.ralph-tasks/*` and one `ralph-logs/` lines from `GITIGNORE_ENTRIES`. If the array ends up empty, leave the array empty (don't delete the block — task 006 will rewrite this whole file).
- Do not rename `RALPH_DIR`. It's a local variable and task 006 deletes this file.

**Step 10 — PRD + task context tree:**
The moves in Step 1 already handled the directory rename. Inside the renamed PRD file itself (`orca-context/prds/006-modes-and-multisession.json`):
- Task descriptions reference `ralph-context/tasks/...` paths multiple times — update to `orca-context/tasks/...`.
- Task 005's own description also says `ralph-context/` → `orca-context/` and `.ralph/` → `.orca/`. Leave that text alone — it's describing the rename retrospectively, and editing it would make the PRD describe a non-event.
- Same rule for task 006 and 008 descriptions — leave intentional "pre-rename `ralph-*`" references alone; those are explicitly describing the legacy state.
- Update any `ralph-context/tasks/006-modes-and-multisession/NNN/context.md` path pointers in task descriptions → `orca-context/...`.

Other files under the old `ralph-context/tasks/` (now `orca-context/tasks/`): **leave historical task docs alone.** They are historical artifacts of prior PRDs. Rewriting them corrupts history without adding value. PRD task 008 explicitly defers the decision on historical task context files.

**Step 11 — framework re-sync:**
After all of the above, copy `framework/` → `.orca/` so the installed copy matches the canonical source. Delete `.orca/processes/build-cycle.md` if it survives the copy (task 002 removed it from `framework/processes/`; it should not reappear in `.orca/`). Verify with `diff -rq framework .orca` — the only expected differences are files in `framework/` that don't install (`framework/template.claude.settings.json` — task 007 moves this; task 005 leaves it where it is).

Concrete re-sync command (the implementer may use any equivalent):
```
rm -rf .orca
mkdir -p .orca
cp -R framework/. .orca/
rm -f .orca/template.claude.settings.json
```

**Step 12 — commit and push:**
One commit: `Rename ralph-docker infrastructure to orca`. Body lists the high-level moves. Push.

## 2. Path vs Prose Distinction

The word "ralph" plays two roles in this repo:

**Path / machinery (replace):**
- Any dotted directory prefix: `.ralph/`, `.ralph-tasks/`.
- Any non-dotted directory: `ralph-context/`, `ralph-logs/`.
- Any script filename: `ralph-start.sh`, `ralph-loop.sh`, `ralph-once.sh`, `ralph-reset.sh`, `ralph-clone.sh`, `ralph-attach.sh`.
- The bash-loop prompt file: `RALPH_PROMPT.md`.
- Docker image tag: `ralph-claude`.
- Docker container / volume name prefixes: `ralph-<foo>`, `ralph-vol-<foo>`.
- Container filter pattern in helper scripts: `name=ralph-`.
- Logger label in banners when it is naming a container, e.g. `🚀 Ralph Container: $CONTAINER_NAME` — the label is naming the machinery, so it becomes `🚀 Orca Container`.

**Process / prose (keep):**
- `/ralph` — skill invocation syntax. Stays as-is everywhere, including inside `.claude/skills/ralph/`.
- "Ralph" as subject of a sentence describing behavior: "Ralph reads the PRD", "Ralph dispatches subagents", "Ralph signaled COMPLETE", "the ralph loop", "the /ralph skill", "Ralph supervises PRD execution".
- "ralph/<prd-name>" git branch prefix (user-stated).
- The word "Ralph" in file titles like `# Ralph` at the top of `framework/ralph.md` — the file is named `ralph.md` and the process is called Ralph.
- The filename `ralph.md` itself (this is the name of the orchestrator instruction file, keyed off the process).

**Rule of thumb:** if you can substitute "the ralph container" for "the orca container" and the sentence still makes sense, it's a path/machinery reference — replace. If the subject is "Ralph" doing something (an actor with behavior), it's the process — keep.

**Heavily mixed files (read line-by-line, don't script):**
- `README.md` — mixes process prose ("Ralph reads the PRD") with paths (`.ralph/seed.md`), script names, command tables. See §3 for the plan.
- `CLAUDE.md` — same mix.
- `framework/seed.md`, `framework/ralph.md`, `framework/processes/prd.md` — almost pure path refs; process prose appears but the subject "Ralph" is rare. Easier than it looks.
- `framework/perspectives/*.md` — each starts with `Read .ralph/seed.md first`. That's a path. Replace.
- `docs/structure.md`, `docs/execution-strategies.md` — pure path-flavored; replace freely.
- `orca-context/prds/006-modes-and-multisession.json` — descriptive prose about the rename itself; follow Step 10 rules.
- `ORCA_PROMPT.md` — one path ref, otherwise process prose.

**Absolute don't-sed rule.** Do not run a single repo-wide `sed -i 's/ralph/orca/g'`. It will turn "Ralph reads the PRD" into "Orca reads the PRD", break `/ralph` to `/orca`, and corrupt branch name examples. The implementer should work file-by-file, using `git grep -n 'ralph'` after each edit to see what's left and classify each hit before changing it.

## 3. File-by-File Action Map

| File | Action |
|------|--------|
| `install.sh` | Minimal: update path literals only (`.ralph`, `ralph-context`, `RALPH_PROMPT.md`, `ralph-loop.sh`, `ralph-once.sh`). Drop `.ralph-tasks/*` and `ralph-logs/` entries from `GITIGNORE_ENTRIES`. File is deleted in task 006 — do not over-invest. |
| `CLAUDE.md` | Replace `.ralph/` with `.orca/`; `ralph-context/` → `orca-context/`; drop the `.ralph-tasks/` bullet entirely; "installed copy of framework/" wording stays; "Stays in ralph-docker only" → "Stays in orca only"; keep "Ralph Framework" heading and "How to Run /ralph" section name. Update example path `ralph-context/prds/001-foundation.json` → `orca-context/prds/001-foundation.json`. Update "ralph-docker repo" phrasing → "orca repo" where present. |
| `README.md` | Heavy edit but mechanical. Keep the title "Ralph Framework" (process is still Ralph). Update: install clone URL `ralph-docker.git` → clone URL unchanged (the GitHub repo will rename separately; keep current URL and add a migration note in the paragraph below). All `.ralph/` → `.orca/`. All `ralph-context/` → `orca-context/`. `.ralph-tasks/` table row → delete. Command examples: `~/ralph/install.sh` stays as a concrete example path — user directory name is cosmetic but for clarity, update to `~/orca/install.sh` (it's describing where the user cloned the infra, not the ralph process). All script names `ralph-start.sh` → `orca-start.sh`, etc. `RALPH_PROMPT.md` → `ORCA_PROMPT.md`. Process prose ("Ralph reads the PRD", "/ralph skill") stays. Add one-line migration note near the "Running multiple sessions" section about pre-rename `ralph-*` Docker volumes being orphaned (see §5). |
| `.gitignore` | Remove the `/ralph-logs/` line and its comment. After this the file may only contain non-ralph entries; that is fine. |
| `Dockerfile` | Grep for `ralph`. Expected: no hits. If found, update. |
| `ralph-start.sh` → `orca-start.sh` | Rename via git mv. Body: container name default `ralph-$FOLDER_NAME` → `orca-$FOLDER_NAME`. Image tag `ralph-claude:latest` → `orca-claude:latest`. Banner label. |
| `ralph-clone.sh` → `orca-clone.sh` | Rename. Body: container/volume name templates `ralph-${REPO_NAME}`, `ralph-vol-${REPO_NAME}` → `orca-*`. Image tag. Help text examples. |
| `ralph-attach.sh` → `orca-attach.sh` | Rename. Body: filter `name=ralph-` → `name=orca-`. Comment describing purpose. |
| `ralph-reset.sh` → `orca-reset.sh` | Rename. Body: grep `^ralph-` → `^orca-`. References to sibling scripts. Volume name hint `ralph-vol-<repo-name>` → `orca-vol-<repo-name>`. |
| `ralph-loop.sh` → `orca-loop.sh` | Rename. Body: default prompt file `RALPH_PROMPT.md` → `ORCA_PROMPT.md`. Delete the `mkdir -p ralph-logs` block, the `LOG_FILE=...` machinery, and the `tail -f ralph-logs` hint lines. Keep the loop and COMPLETE detection. Implementer's call whether to keep tee-to-file at all (see §4). |
| `ralph-once.sh` → `orca-once.sh` | Rename. Default prompt file → `ORCA_PROMPT.md`. |
| `RALPH_PROMPT.md` → `ORCA_PROMPT.md` | Rename. Body: `.ralph/ralph.md` → `.orca/ralph.md`. First-line prose "You are Ralph operating in bash-loop mode" stays. |
| `docs/design-principles.md` | Grep; expected to have zero path refs. Leave any "ralph" process prose alone. |
| `docs/structure.md` | Replace `.ralph/` → `.orca/`, `ralph-context/` → `orca-context/`, and the whole `.ralph-tasks/` section — delete it (see §4). `.gitignore considerations` section: drop the `.ralph-tasks/*` and `ralph-logs/` lines. The self-installation paragraph `ralph-docker repo` → `orca repo`. |
| `docs/execution-strategies.md` | Replace path refs and script names. Process prose stays. The `RALPH_PROMPT.md (a thin wrapper that points to .ralph/ralph.md)` line → `ORCA_PROMPT.md (a thin wrapper that points to .orca/ralph.md)`. The bottom table row `via RALPH_PROMPT.md` → `via ORCA_PROMPT.md`. |
| `framework/seed.md` | Single reference at top: `.ralph/perspectives/` and `.ralph/processes/prd.md` → `.orca/...`. |
| `framework/ralph.md` | Three path refs: `.ralph/perspectives/`, mode perspectives path, `.ralph/processes/prd.md`. Branch example `ralph/<prd-name>` stays (user-stated). |
| `framework/processes/prd.md` | `.ralph/modes/<mode>/MODE.md` → `.orca/modes/...`. `ralph-context/tasks/...` → `orca-context/tasks/...`. |
| `framework/perspectives/*.md` | Each has `.ralph/seed.md` at the top. Replace. No other path hits expected; grep to confirm. |
| `framework/modes/code/MODE.md` | `.ralph/perspectives/` → `.orca/perspectives/`. Any `ralph-context/` refs → `orca-context/`. |
| `framework/templates/prd.json` | Grep; likely clean. If any `ralph-context` refs appear, update. |
| `templates/CLAUDE.md.template` | `.ralph/seed.md` → `.orca/seed.md`. |
| `templates/.claudeignore` | Drop the `ralph-logs/` block (see §4). |
| `templates/.git-hooks/pre-push` | Grep; likely clean. |
| `.claude/skills/ralph/SKILL.md` | `.ralph/ralph.md` → `.orca/ralph.md`. Skill name `ralph` stays. |
| `.claude/skills/refine/SKILL.md` | Example path `ralph-context/prds/...` → `orca-context/prds/...`. |
| `.claude/skills/discover/SKILL.md` | Grep; update if hits. |
| `orca-context/README.md` (was `ralph-context/README.md`) | `.ralph/` → `.orca/`. Heading `# ralph-context` → `# orca-context`. |
| `orca-context/prds/006-modes-and-multisession.json` | See Step 10. Update task description path pointers to `orca-context/tasks/...`. Preserve the rename-describing prose (tasks 005, 006, 008). |
| `orca-context/prds/*.json` (other PRDs) | Leave alone — historical. They describe work that landed at paths that existed at the time. Touching them rewrites history. |
| `orca-context/tasks/**/*.md` (historical task docs) | Leave alone — same reason. |
| `orca-context/tasks/006-modes-and-multisession/005/context.md` | Leave alone — this is the brainstorming input and its literal references to the old names are the point. |
| `orca-context/tasks/006-modes-and-multisession/006/context.md` | This is future-looking. Update `ralph-context/tasks/...` path hints to `orca-context/...` **only** where the text is referring to the new structure, not the pre-rename state. Read line-by-line. (If unsure, leave it — task 006 does its own planning.) |
| `BACKLOG.json` | Leave alone unless it contains live path references that will mislead future work. Grep; likely only prose mentions. |
| `progress.txt` | Leave alone — historical log. |
| `prds/` (old root-level bash-loop PRDs) | Leave alone — historical. |
| `.claude/settings.json`, `.claude/settings.local.json` | Leave alone. Task 007 handles settings. |
| `framework/template.claude.settings.json` | Leave. Task 007 moves it. |
| `WHY.md` | Grep; probably zero path refs. If any, treat as README-style. |

## 4. `.ralph-tasks/` and `ralph-logs/` Handling

**Decision: delete both. Bash-loop mode keeps living, but without the log-file plumbing.**

Rationale:
- `.ralph-tasks/`: PRD and context file agree it's a ghost. Nothing writes to it, nothing reads from it, `.gitkeep` never existed. Delete with prejudice.
- `ralph-logs/`: only `ralph-loop.sh` writes there. The log files are per-iteration transcripts of `claude -p` output. The value is "I can tail -f what Ralph is doing" during a long unattended run. But the same output already streams to the terminal (the script echoes `$OUTPUT`), and Docker itself captures container stdout if the user wants persistence. The logs dir has accumulated ~20+ stale files across old runs and is gitignored anyway. The user uses subagent mode per the Memory; bash-loop is a supported-but-secondary path.

Bash-loop stays as a mode (per `docs/execution-strategies.md` and the PRD's explicit mention of it), but the log plumbing can go. `orca-loop.sh` keeps the iteration loop, echo, and COMPLETE detection; drops the `mkdir`, `LOG_FILE=`, file-header writes, tee-to-file, and "tail -f" hints.

If the implementer disagrees and wants to preserve logs, rename `ralph-logs/` → `orca-logs/` and leave the plumbing. Both are defensible; the simpler call is to drop it.

**Concrete cleanups from the log removal:**
- `orca-loop.sh`: remove logging block.
- `.gitignore`: delete `/ralph-logs/`.
- `templates/.claudeignore`: delete the `RALPH LOGS` block.
- `docs/structure.md`: delete the `ralph-logs/` entry in the `.gitignore Considerations` section.
- `docs/execution-strategies.md`: no log refs; nothing to do.
- `install.sh`: drop from GITIGNORE_ENTRIES (already in §3).
- `README.md`: no log refs in body; nothing to do beyond what's in §3.
- Delete the `ralph-logs/` directory from the working tree.

**Concrete cleanups from `.ralph-tasks/` removal:**
- `CLAUDE.md`: delete the `.ralph-tasks/` bullet in "What This Repo Contains".
- `README.md`: delete the `.ralph-tasks/` row in "Repository Structure".
- `docs/structure.md`: delete the entire "### `.ralph-tasks/` — Ephemeral Agent Workspaces" section (lines 66-110 roughly — through the end of the "progress.txt Conventions" subsection). The `progress.txt` convention was a bash-loop artifact; `orca-context/tasks/<prd>/<task>/` is where work happens now.
- `install.sh`: drop `.ralph-tasks/*/debug-*` and `.ralph-tasks/*/scratch-*` from GITIGNORE_ENTRIES.

Historical docs under `orca-context/tasks/` that reference `.ralph-tasks/` stay — historical accuracy.

## 5. Docker Image Tag and Volume Prefix

**Image tag:** `ralph-claude:latest` → `orca-claude:latest`. Referenced in:
- `orca-start.sh` (was `ralph-start.sh`), line 61.
- `orca-clone.sh` (was `ralph-clone.sh`), line 94.

The image is built with `docker build -t <tag> .`. After the rename the user will need to rebuild once with `docker build -t orca-claude:latest .`. Their old `ralph-claude` image remains on disk until they prune — harmless.

**Container name prefix:** `ralph-<folder>` → `orca-<folder>`. Referenced in `orca-start.sh`, `orca-clone.sh`, `orca-attach.sh`, `orca-reset.sh`. After the rename, an existing running container named `ralph-myproj` is untouched on the user's machine — `orca-start.sh ~/code/myproj` will try to create `orca-myproj` and succeed, because the names differ. Old container becomes an orphan until manual `docker rm`.

**Volume name prefix:** `ralph-vol-<repo>` → `orca-vol-<repo>` (in `orca-clone.sh`) and `${CONTAINER_NAME}_node_modules` (in `orca-start.sh` — this is already derived from the container name, so it follows automatically). Old `ralph-vol-*` volumes become orphans on user machines.

**Migration note for README** (implementer drops one short paragraph into the README, probably near "Running multiple sessions" or at the bottom):

> **Migrating from `ralph-*` names:** If you previously used this framework when its infrastructure was called `ralph-docker`, your existing `ralph-<name>` Docker containers and `ralph-vol-*` volumes keep working but are now orphaned (new runs create `orca-*` names). Run `docker ps -a --filter name=ralph-` and `docker volume ls | grep ralph-vol-` to find them; remove with `docker rm -f` and `docker volume rm` when you're done with the last ralph-era session. Rebuild the image once: `docker build -t orca-claude:latest .`.

## 6. Self-Hosting Continuity

After the implementer's commit, Ralph must be able to resume PRD 006 to work tasks 006-008. That means:

- `.claude/skills/ralph/SKILL.md` points at `.orca/ralph.md` ✓
- `.orca/ralph.md` exists and its path references resolve (`.orca/perspectives/`, `.orca/processes/prd.md`) ✓
- `.orca/processes/prd.md` points at `.orca/modes/<mode>/MODE.md` ✓
- `framework/` edits are mirrored into `.orca/` via the Step 11 re-sync ✓
- PRD file lives at `orca-context/prds/006-modes-and-multisession.json` and its self-references (task description path pointers) resolve ✓
- Task directories accessible at `orca-context/tasks/006-modes-and-multisession/<id>/` ✓
- CLAUDE.md tells agents to read `.orca/seed.md` ✓
- `templates/CLAUDE.md.template` tells newly-installed projects to read `.orca/seed.md` ✓

The next `/ralph orca-context/prds/006-modes-and-multisession.json` invocation reads the PRD, follows `.orca/ralph.md`, and dispatches the task 005 code-cleaner. That dispatch needs to find `orca-context/tasks/006-modes-and-multisession/005/` — it will.

**Commit atomicity is load-bearing.** If the implementer splits this into two commits and the first one moves directories without updating references, `/ralph` cannot run on the intermediate state. Single commit only.

**The PRD's own path changed.** Anyone with a scrollback buffer or bookmark pointing at `ralph-context/prds/006-modes-and-multisession.json` will get a not-found. The user is aware (they wrote the context file). Human invocations update with the new path.

## 7. Verification Strategy

After the commit, run these checks before pushing:

**Residual grep sweep** — all must return zero hits:
```
git grep -n 'ralph-context' -- . ':!orca-context/tasks/**' ':!orca-context/prds/!(006-modes-and-multisession.json)' ':!BACKLOG.json' ':!progress.txt' ':!prds/' ':!WHY.md'
git grep -n 'ralph-logs'
git grep -n 'RALPH_PROMPT'
git grep -n 'ralph-claude'
git grep -n '\.ralph-tasks'
git grep -n '\.ralph/' -- . ':!orca-context/tasks/**' ':!BACKLOG.json' ':!progress.txt'
git grep -n 'ralph-start\.sh\|ralph-loop\.sh\|ralph-once\.sh\|ralph-reset\.sh\|ralph-clone\.sh\|ralph-attach\.sh' -- . ':!orca-context/tasks/**'
```

**Intentional hits that should survive** — grep these and inspect:
```
git grep -n '/ralph'                    # skill invocation, keep
git grep -n 'ralph/\<prd'                # branch naming, keep
git grep -n '\bRalph\b'                  # process prose, keep (subject of sentences)
```

**Self-host smoke test (mental walkthrough, no actual dispatch needed):**
1. Open `.claude/skills/ralph/SKILL.md` — it points at `.orca/ralph.md`. ✓
2. Open `.orca/ralph.md` — it points at `.orca/perspectives/` and `.orca/processes/prd.md`. Both exist. ✓
3. Open `.orca/processes/prd.md` — path references resolve. ✓
4. Check `orca-context/prds/006-modes-and-multisession.json` exists and task 005 architect step is complete. ✓

**Docker smoke test (optional, if the implementer can run docker locally):**
```
docker build -t orca-claude:latest .
./orca-start.sh /tmp/empty-repo  # should fail cleanly (no .git) — proves script loads
```

**`git status` after the commit:** working tree clean. No untracked leftovers from the directory moves.

## 8. Implementer Scope: One Commit

**One commit. Non-negotiable for the self-hosting reason.** The intermediate states are non-functional:
- After Step 1 but before Step 3: `/ralph` can't find `.orca/ralph.md` because SKILL.md still says `.ralph/`.
- After any partial step: `.orca/` and `framework/` are out of sync.

Title: `Rename ralph-docker infrastructure to orca`

Body: short bullet list of the classes of change (directory renames, script renames, path substitutions in framework, re-sync of .orca from framework, delete .ralph-tasks and ralph-logs, migration note in README). The co-author footer and no-AI-attribution-in-title rules apply as normal.

Push the branch. The PR updates automatically — task 005 pipeline on the PRD dashboard flips architect→complete→implementer→in-progress on next Ralph run.

**No deliberate exceptions.** If the implementer hits something unexpected (e.g., a file with a genuine ambiguity about path vs prose), they should resolve inline and commit together. If a problem is truly big enough to warrant a split, they should mark task 005 `needs_input` and ask — questions are enabled on this PRD? (Check the PRD top-level `questions` field before asking. If absent/false, use judgment per seed.md.)
