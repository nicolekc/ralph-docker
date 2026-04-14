# Task 006 — Easy Install via Skill: Exploration

Research-only. Architect picks the mechanism.

---

## 1. Skill-install patterns (April 2026)

The dominant Anthropic-blessed install pattern in April 2026 is the **plugin marketplace**. Skills are still installable in isolation by hand-cloning into `~/.claude/skills/<name>/`, but if you want a single-instruction install of *multiple* artifacts (skills + commands + agents + hooks + settings) from a GitHub repo, plugins/marketplaces are the canonical mechanism.

Key facts (from `https://code.claude.com/docs/en/plugin-marketplaces` and `…/plugins`):

- **Marketplace = a git repo with `.claude-plugin/marketplace.json`** that lists one or more plugins.
- **Plugin = a directory with `.claude-plugin/plugin.json`** that bundles `skills/`, `commands/`, `agents/`, `hooks/`, `mcpServers/`, `lspServers/`.
- **Install commands work without leaving Claude Code**:
  ```
  /plugin marketplace add owner/repo
  /plugin install <plugin-name>@<marketplace-name>
  ```
  These also exist as non-interactive `claude plugin marketplace add …` / `claude plugin install …` for scripting.
- **Plugin entries can specify a `source`** of `github`, `git-subdir`, `url`, `npm`, or relative path. So one marketplace can list several plugins from several repos.
- **Plugins are copied to a cache** at `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`. Plugin files cannot reach outside the plugin dir at install time.
- **Hooks** in `plugin.json` (`PostToolUse`, etc.) run during user sessions, not at install. There is **no documented "post-install" hook** — installation just unpacks files.
- **`extraKnownMarketplaces` in `.claude/settings.json`** auto-prompts a project's collaborators to add the marketplace when they trust the folder.
- **Skills inside an installed plugin** are namespaced as `plugin-name:skill-name`.

What this means for Orca: a `/plugin install orca@orca-marketplace` line installs the skills (`/orca`, `/discover`, `/refine`, `/repo-memory`) automatically. It does **not** by itself lay down `.orca/`, `orca-context/`, `.claudeignore`, `.git-hooks/`, the settings template, etc. — those are project-tree changes outside the plugin cache. Something has to do that work *after* install.

Sources surveyed:
- Official: `code.claude.com/docs/en/skills`, `…/plugin-marketplaces`, `github.com/anthropics/skills`, `github.com/anthropics/claude-plugins-official`.
- Community curators: `alirezarezvani/claude-skills` (claims 232+ skills, ships an `openclaw-install.sh` curl-bash one-liner), `VoltAgent/awesome-openclaw-skills`, `travisvn/awesome-claude-skills`, `claudemarketplaces.com`.
- "openclaw" / "OpenClaw" appears to be a third-party superset (CLI proxy + plugin host) layered on Claude Code, with its own ClawHub registry and `npx clawhub@latest install <skill>`. **It is not Anthropic's own pattern** — the architect should not feel bound to mimic openclaw's CLI; the Anthropic-native equivalent is `/plugin marketplace add` + `/plugin install`.

### Bootstrap-from-bare-message

There is **no** documented mechanism for "user types `install Orca from <url>` to a fresh Claude Code session and Claude executes it." Without an Orca-specific skill already loaded, Claude has no playbook. It might try to figure it out on its own, but that's not a deterministic install. The bootstrap requires *some* prior step.

The closest first-class pattern is: **the user types `/plugin marketplace add github-owner/orca && /plugin install orca@orca`** — two short commands, no shell needed, no curl, no manual file copy. That's about as close to a single instruction as Claude Code currently gets.

---

## 2. Bootstrap options and trade-offs

Five viable shapes, in rough order of friction:

### A. Plugin marketplace + install skill inside the plugin

User runs:
```
/plugin marketplace add <github-owner>/orca
/plugin install orca@orca
/orca-install
```

- The `/plugin install` step lays down skills (including a new `/orca-install` skill) into the Claude Code plugin cache.
- The `/orca-install` skill, when invoked, walks the project tree and writes `.orca/`, `orca-context/`, hooks, gitignore, settings template, etc.
- **Pro**: Native Anthropic mechanism. No curl. Auto-updates when the marketplace is updated. `/plugin install` already provides progress UI.
- **Pro**: Re-running `/orca-install` handles upgrade and migration, since the skill is already installed.
- **Con**: Three lines instead of one. The user has to remember the marketplace name. Mitigated by README copy-paste.
- **Con**: The plugin cache and the project-tree install diverge. We have to decide whether `.orca/` is a copy of plugin contents (and how it gets refreshed) or whether the skills read from the plugin cache directly. (See §7 open questions.)

### B. Curl one-liner that installs everything

User runs in a shell:
```
curl -fsSL https://orca.dev/install.sh | bash
```

- The script clones the repo, copies framework + skills into the project, configures hooks, etc. (Essentially today's `install.sh` repackaged.)
- **Pro**: One command. Total control over what lands.
- **Con**: User leaves Claude Code. Defeats the "tell Claude to install it" vision in the task description.
- **Con**: Curl-bash is a security smell some users avoid.

### C. User pastes a snippet that creates a bootstrap skill

User pastes a few lines into a new `~/.claude/skills/install-orca/SKILL.md`, then runs `/install-orca`.

- **Pro**: No external script. The "skill" itself contains the URL and minimal instructions ("fetch this repo, copy these files to these places, then ask the user about settings").
- **Con**: Fiddly — user has to mkdir, paste, save. Error-prone.
- **Con**: Provides no mechanism advantage over (A) since they end up doing the same install logic.

### D. Rely on a generic "install-skill-from-github" skill

If the user already has a community skill that knows how to install from a URL, they say `install Orca from <url>` and that skill drives the work.

- **Pro**: Closest to the dream UX.
- **Con**: We do not control whether the user has such a skill. Cannot rely on it. **Should not be the primary path.**

### E. `extraKnownMarketplaces` via project settings (chicken-and-egg)

If the user has already cloned the Orca repo (or a project that uses Orca), `.claude/settings.json` can carry an `extraKnownMarketplaces` entry that auto-prompts on folder trust. But this only helps for *second-time* users who already have a project wired up. It does nothing for fresh installs.

### Recommendation skeleton (architect's call)

**Primary path**: (A) — marketplace + plugin + `/orca-install` skill. Closest to native, single-flow, upgradable.

**Fallback path**: (B) — keep a `curl install.sh | bash` for users who prefer shell or are scripting CI. The script itself can simply do `claude plugin marketplace add … && claude plugin install … && claude -p "/orca-install ."` if we want symmetry with the primary path.

**Decision the architect must make**: where does the install logic live? Two reasonable shapes:
1. **Logic in the install skill** — `/orca-install` reads the plugin cache and copies needed framework files into `.orca/`. The plugin cache is the source of truth.
2. **Logic in a script bundled with the plugin** — `/orca-install` shells to a Python or bash script in `${CLAUDE_PLUGIN_ROOT}/scripts/install.py`. Easier idempotency, harder to read at a glance.

---

## 3. Install inventory (what lands where)

Authoritative inventory from `find /workspace/framework /workspace/.claude/skills /workspace/templates`:

### Framework files (overwrite-on-upgrade)

Source `framework/` → target `.orca/`:

| Source path                                       | Target                                            | Notes                                                                 |
|---------------------------------------------------|---------------------------------------------------|-----------------------------------------------------------------------|
| `framework/seed.md`                               | `.orca/seed.md`                                   |                                                                       |
| `framework/ralph.md`                              | `.orca/ralph.md`                                  |                                                                       |
| `framework/processes/prd.md`                      | `.orca/processes/prd.md`                          |                                                                       |
| `framework/perspectives/architect.md`             | `.orca/perspectives/architect.md`                 |                                                                       |
| `framework/perspectives/code-cleaner.md`          | `.orca/perspectives/code-cleaner.md`              |                                                                       |
| `framework/perspectives/code-reviewer.md`         | `.orca/perspectives/code-reviewer.md`             |                                                                       |
| `framework/perspectives/design-reviewer.md`       | `.orca/perspectives/design-reviewer.md`           |                                                                       |
| `framework/perspectives/drafter.md`               | `.orca/perspectives/drafter.md`                   |                                                                       |
| `framework/perspectives/explorer.md`              | `.orca/perspectives/explorer.md`                  |                                                                       |
| `framework/perspectives/implementer.md`           | `.orca/perspectives/implementer.md`               |                                                                       |
| `framework/perspectives/planner.md`               | `.orca/perspectives/planner.md`                   |                                                                       |
| `framework/perspectives/qa-engineer.md`           | `.orca/perspectives/qa-engineer.md`               |                                                                       |
| `framework/perspectives/spec-reviewer.md`         | `.orca/perspectives/spec-reviewer.md`             |                                                                       |
| `framework/modes/code/MODE.md`                    | `.orca/modes/code/MODE.md`                        |                                                                       |
| `framework/templates/prd.json`                    | `.orca/templates/prd.json`                        | Used by `/refine` and humans drafting PRDs                            |

### Skills (install scope = either project `.claude/skills/` or user `~/.claude/skills/`)

Source `.claude/skills/` → target `.claude/skills/` (project) **or** packaged inside the plugin (user-level):

| Skill                                       | Files                                                                                |
|---------------------------------------------|--------------------------------------------------------------------------------------|
| `ralph`                                     | `SKILL.md`                                                                           |
| `discover`                                  | `SKILL.md`                                                                           |
| `refine`                                    | `SKILL.md`                                                                           |
| `repo-memory`                               | `SKILL.md` + `references/{audit,detection,install,utility}.md`                       |

If the install ships as a Claude Code plugin, skills live in the plugin cache and namespace as `orca:ralph`, `orca:discover`, etc. If the skills are written into the project tree (current install.sh behavior), they stay project-scoped at `.claude/skills/<name>/`. **Architect must decide**: plugin-scoped (clean, namespaced, one-line install) or project-scoped (visible in repo, current behavior).

### Templates and scaffolds

| Source                             | Target                                                              | Type                  |
|------------------------------------|---------------------------------------------------------------------|-----------------------|
| `templates/CLAUDE.md.template`     | `<project>/CLAUDE.md`                                               | User file (create-only — never overwrite) |
| `templates/.claudeignore`          | `<project>/.claudeignore`                                           | Framework-managed     |
| `templates/.git-hooks/pre-push`    | `<project>/.git-hooks/pre-push` (chmod +x; `git config core.hooksPath .git-hooks`) | Framework-managed     |
| `framework/template.claude.settings.json` | `<project>/.claude/settings.json` **or** `~/.claude/settings.json` (user choice; merge, not overwrite) | **Templated, see task 007** |
| (mkdir + .gitkeep) | `orca-context/{overrides,knowledge,prds,designs,tasks}/.gitkeep` | Scaffold (create-only) |

### Files that need post-processing (NOT literal copies)

- **`framework/template.claude.settings.json`** — currently a literal JSON. For task 007 it must be *offered* with context (what each setting does, why it's recommended, where it goes — project or user). When applied, **merge** into the chosen `settings.json` instead of clobbering existing keys. See §6.
- **`templates/CLAUDE.md.template`** — placeholder text says "run /discover to populate." Should not overwrite an existing CLAUDE.md.
- **`templates/.git-hooks/pre-push`** — must be `chmod +x` after copy and `git config core.hooksPath .git-hooks` must be set (idempotently).

### Files that MUST NOT be copied to the target project

- **`framework/`** itself (the source tree). The target gets `.orca/` (a derived copy), not `framework/`.
- **`docs/`**, **`CLAUDE.md`** (the dev-facing one for ralph-docker itself), **`BACKLOG.json`**, **`README.md`**, **`WHY.md`**, **`progress.txt`** — repo-internal, not framework.
- **Docker / bash infra**: `Dockerfile`, `orca-start.sh`, `orca-attach.sh`, `orca-clone.sh`, `orca-reset.sh`, `orca-loop.sh`, `orca-once.sh`, `ORCA_PROMPT.md`. These ship only if the user wants bash-loop mode (today's `--bash-loop` flag). **Architect should decide whether to keep bash-loop mode supported by the new installer.** If kept, that's a separate opt-in branch; if dropped, those files don't ship at all.
- **`orca-context/`** itself (the dev-facing one with this repo's PRDs). Only the empty scaffold gets created in the target.
- **`.git-hooks/`** in this repo if any (currently none) — only the template under `templates/.git-hooks/` ships.
- **`node_modules/`**, **`prds/`** (legacy?), **`install.sh`** (deleted by this task).

### Things to scaffold but leave empty

- `orca-context/{overrides,knowledge,prds,designs,tasks}/.gitkeep` — directory shape only, no content.

### Things explicitly NOT to scaffold (per context.md)

- `.orca-tasks/` — ghost directory (`.ralph-tasks/` was unused; do not recreate under the new name).
- `orca-logs/` — only if bash-loop mode is preserved.

---

## 4. Three-state handling (fresh / upgrade / migrate)

### State A: Fresh — no `.orca/`, no `.ralph/`

What's tricky:
- **Detecting "fresh"**: easy — `[ ! -d .orca ] && [ ! -d .ralph ]`.
- **Existing files we'd touch**: `CLAUDE.md` may pre-exist (user-written). Must `copy_user_file` semantics — create only, never overwrite. `.gitignore` may pre-exist; append-merge, never replace.
- **Settings**: project may or may not have `.claude/settings.json`. Task 007 wants user choice + merge. Fresh case is the easy one (no merge conflicts), but we still must ask.
- **`.git`**: confirm the directory is a git repo (today's installer enforces this); decide whether the new install requires it or just warns.

### State B: Upgrade — `.orca/` exists

What's tricky:
- **Distinguishing framework files from user content**:
  - Inside `.orca/` everything is framework — overwrite freely. (Framework files have always been read-only from the user's perspective.)
  - Inside `orca-context/` everything is user content — never touch. Only ensure the directory shape exists (don't even add `.gitkeep` if files are already there).
  - Inside `.claude/skills/` if skills land project-scoped, they're framework — overwrite. If user added their own skills, they're at sibling skill names; we only touch `ralph/`, `discover/`, `refine/`, `repo-memory/`.
- **Removed files**: if a future framework version *removes* a perspective or process file, copy-on-top doesn't delete the old one. Need a sweep step that knows the canonical file list and removes stale `.orca/**` files not in it. (Today's `install.sh` does NOT do this — gap to flag.)
- **`CLAUDE.md`**: must not touch. User may have customized it heavily.
- **`.claudeignore`**: today's installer treats this as framework-managed (overwrites). Architect should reconsider — users often add project-specific ignores. Probably should be append-merge or create-only after first install.
- **`.gitignore`**: append-only, missing entries only. (Today's installer does this; current `GITIGNORE_ENTRIES` array is empty so this is moot but the mechanism should stay.)
- **`.git-hooks/pre-push`**: framework-managed, overwrite. `core.hooksPath` only set if not already pointing somewhere (today's installer always sets it; consider warning if user has a different hooks path).
- **Settings**: do NOT re-prompt every upgrade. Task 007 says "never silent" but presumably the prompt is a one-time thing per install. Need a marker (e.g., a key in the settings or a sentinel file) to avoid re-asking.

### State C: Rename migration — `.ralph/` exists

What's tricky:
- **Detection**: `[ -d .ralph ] || [ -d ralph-context ]` triggers migration before normal upgrade.
- **Operations** (must be `git mv` so history follows; the migration is a real rename):
  - `git mv .ralph .orca`
  - `git mv ralph-context orca-context`
  - `git mv .ralph-tasks .orca-tasks` — **NO**, per context.md, `.ralph-tasks/` is a ghost; if it exists, **delete** it instead of migrating.
  - `git mv ralph-logs orca-logs` — only if bash-loop mode preserved.
  - `git mv RALPH_PROMPT.md ORCA_PROMPT.md` — only if bash-loop mode preserved.
  - `git mv ralph-loop.sh orca-loop.sh`, etc. — only if bash-loop preserved.
- **Inside-file references** that need rewriting (grep-and-sed):
  - `.ralph/` → `.orca/` in CLAUDE.md, settings.json, any project doc.
  - `ralph-context/` → `orca-context/` similarly.
  - Skill SKILL.md files reference `.orca/` — they'll be overwritten by the upgrade step, so this only matters for *user-written* files.
- **`core.hooksPath`**: pre-rename installs might point at `.git-hooks` already; OK. If they pointed somewhere with "ralph" in the name, fix.
- **Then run upgrade**: after the migration, the project looks like an existing `.orca/` install, so the upgrade pass takes over.
- **Edge case**: someone has BOTH `.ralph/` AND `.orca/`. Architect needs a policy — probably "stop and ask" via a question (or refuse with a clear error).
- **Edge case**: dirty git working tree. `git mv` won't blow up, but the user should commit/stash first. Refuse to migrate if `git status` is dirty? Or do it anyway and let them review the diff?

---

## 5. install.sh analysis (keep / drop)

`install.sh` is 307 lines. Walk-through:

### Worth replicating

- **Distinguish framework vs user files** (`copy_framework_file` overwrites; `copy_user_file` creates-only). This *is* the core install model. Keep the mental model.
- **Idempotency tracking** (CREATED / UPDATED / UNCHANGED arrays + summary at the end). The new install needs an end-of-run report. With `cmp -s` (or any content-equality check), report what actually changed vs. what was already current.
- **Walk `framework/` and copy each file under `.orca/`** preserving structure (line 116-153). Same logic needed.
- **`orca-context/` scaffold with `.gitkeep`** in each subdir (lines 181-189). Keep.
- **Git hooks**: copy `pre-push`, `chmod +x`, `git config core.hooksPath .git-hooks` (lines 207-217). Keep, but make `core.hooksPath` set conditional on it being unset or already-correct (today's installer overwrites unconditionally — minor bug).
- **`.gitignore` append-merge** (lines 221-251). Keep the mechanism even though the entry list is currently empty.
- **`--bash-loop` opt-in branch** (lines 253-272) — keep iff bash-loop mode survives. This is also where `ORCA_PROMPT.md`, `orca-loop.sh`, `orca-once.sh` get installed. **Architect should decide bash-loop's fate.** Task 005 mentioned it might be kept.

### Drop / change

- **Argument parsing and target-dir handling** (lines 17-68). A skill running inside Claude Code already knows the project root (`cwd`). No `$1` parsing needed.
- **`set -e`, bash-isms, `BASH_SOURCE`, `find -path -prune`** (line 144 `roles/` exclusion). The "exclude `roles/`" carve-out is dead code — `framework/` no longer has a `roles/` directory. Drop.
- **The "Next steps" hint at the bottom** (lines 300-304) — useful in shell, redundant inside Claude Code where the skill can just say so directly.
- **Hard-fail on missing `.git`** (lines 61-65) — a skill can offer to `git init` for the user instead of erroring.
- **No upgrade or migration logic** — the installer treats everything as a clean install with copy-or-skip semantics. No detection of `.ralph/`, no rename. The new install must add this; it's not just a port.
- **No removal of stale framework files** (gap). If `framework/perspectives/old-role.md` is deleted in a release, the old `.orca/perspectives/old-role.md` in users' projects lingers forever. New installer should know the canonical file set and prune.
- **Settings template not handled**. `framework/template.claude.settings.json` exists but `install.sh` never copies it. Task 007 wires that up — new install must.

### Net

The new install is *not* "rewrite install.sh as a skill." It's a redesign with overlapping ingredients:
- Three-state branching (fresh/upgrade/migrate) up front.
- Settings-template prompt in the middle.
- Stale-file pruning at the end.
- All inside a Claude-Code-native flow with no terminal commands required of the user.

---

## 6. Task 007 integration notes

Current location: `framework/template.claude.settings.json` — sibling of `framework/seed.md`, `framework/ralph.md`, etc. Contents:

```json
{
  "alwaysThinkingEnabled": true,
  "effortLevel": "high",
  "env": {
    "CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING": "1",
    "MAX_THINKING_TOKENS": "64000",
    "CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY": "30",
    "CLAUDE_CODE_AUTO_COMPACT_WINDOW": "200000"
  }
}
```

Five settings, all aimed at "use the model hard, don't auto-compact too aggressively, don't adaptively reduce thinking, run lots of tools in parallel."

Task 007 has its own pipeline (plan complete; implementer + code-cleaner pending). Its description says the file should "probably join `framework/templates/prd.json`" — i.e., move to `framework/templates/template.claude.settings.json`. The install skill must:

1. **Read** the template from `.orca/templates/` (after task 007 moves it) or from the plugin cache.
2. **Show the user** what the settings do — render them with a one-line explanation per key. (Suggested copy lives in task 007's design, not here.)
3. **Ask destination**: project (`.claude/settings.json`) or user (`~/.claude/settings.json`).
4. **Ask apply/skip**: never silent.
5. **If apply**: deep-merge into the chosen settings file. Do NOT overwrite — preserve any existing keys the user has set. For `env`, merge per-key (don't replace the whole `env` block).
6. **If skip**: leave no trace.
7. **Idempotency**: don't re-prompt on every upgrade. Sentinel options: a `.orca/.settings-prompted` marker file, or a `meta.orca-version` key in settings (less invasive). Architect picks.

The settings template change for task 007 is small (move file). The wiring change (steps 1-7 above) is the install skill's responsibility — task 006's territory.

---

## 7. Open questions for the architect

Decisions task 006 needs settled before design starts:

1. **Plugin marketplace or project-tree skills?** I.e., do skills live in `~/.claude/plugins/cache/orca/orca/skills/` (plugin scope) or `<project>/.claude/skills/` (current scope, committed to user's repo)? Plugin scope buys: `/plugin install`, namespace cleanliness, auto-updates, optional user-vs-project install. Project scope buys: visible in `git log`, no Claude Code plugin system dependency, today's behavior preserved. **Recommend plugin scope** unless there's a reason to keep skills in-tree (e.g., user wants to fork them per project).

2. **Where does the install logic live?** (a) Inside the `/orca-install` skill body as natural-language instructions Claude follows, (b) a script in `${CLAUDE_PLUGIN_ROOT}/scripts/` the skill shells out to, or (c) hybrid (skill orchestrates, calls scripts for atomic operations). (a) is most "Orca-native"; (c) is most reliable for things like file diffing.

3. **`.orca/` source of truth in plugin mode**: if skills live in the plugin cache, do we still write framework files to `.orca/` in the project? Two options: (i) Yes — framework files travel with the project so `git log` shows what version was active, and skills like `/ralph` read from `.orca/seed.md`. (ii) No — skills read from `${CLAUDE_PLUGIN_ROOT}` directly, and there's no `.orca/` in the project. (i) preserves current behavior and lets users override perspectives per-project (`orca-context/overrides/`). **Recommend (i)** — keep `.orca/` in the project; the plugin install only adds the install skill on top.

4. **Bash-loop mode survival.** Today's installer has a `--bash-loop` flag that copies `ORCA_PROMPT.md` + `orca-loop.sh` + `orca-once.sh`. PRD task 005 mentioned this is conditional. If bash-loop is alive, the new install needs an opt-in path (skill prompt: "do you want bash-loop mode?"). If dead, drop these files and the prompt entirely.

5. **Stale-file pruning policy.** The current installer never deletes obsolete framework files. Should the new install carry a manifest of canonical files and prune anything else inside `.orca/`? Risks: deleting things the user (incorrectly) put there. Mitigation: only prune *inside `.orca/`* and only files matching framework filename patterns; surface a list of unexpected files for the user to handle. **Recommend yes, with a list-and-confirm step.**

6. **Migration safety.** Should the installer refuse to migrate when `git status` is dirty? Or stage everything and present a single migration commit? **Recommend**: if dirty, ask the user to commit/stash first; otherwise, do the migration in one commit titled "Migrate from ralph to orca paths."

7. **Both `.ralph/` and `.orca/` present.** Policy? Refuse with a clear error, or assume the user is mid-migration and merge intelligently? **Recommend**: refuse and explain — this is too rare and too dangerous to auto-resolve.

8. **`.claudeignore` ownership.** Today: framework-managed (overwrite). Reality: users want to add project-specific ignores. Switch to: create-only on first install, leave alone on upgrade?

9. **Marketplace name.** What's the marketplace's `name` and `owner.name` in `marketplace.json`? Check the reserved-names list (`agent-skills`, `claude-code-marketplace`, etc. — `orca` is fine). Public-facing string.

10. **Marketplace repo hosting.** Same repo as Orca itself (a `.claude-plugin/marketplace.json` at the root pointing to `./` as the plugin), or a separate `orca-marketplace` repo? Same-repo is simpler; user runs `/plugin marketplace add <owner>/orca`. Separate-repo lets us iterate on marketplace metadata without a framework release.

11. **Versioning.** Plugins support `version` in `plugin.json`. Does Orca want semver? Single `version` field bumped per release? This affects whether users can pin: `/plugin install orca@orca-marketplace --version 1.2.0` style.

12. **Self-install.** This repo is self-hosted: `framework/` → `.orca/`. After this PRD, does the dev workflow still use `install.sh` (deleted) or does it use the new install skill against the local clone? If the latter, the install skill needs a "local source" mode (read framework files from `framework/` instead of plugin cache).

---

## Top 3 findings

1. **Plugin marketplaces are the native April 2026 install pattern.** Two-line install (`/plugin marketplace add owner/orca` then `/plugin install orca@orca`) is as close as Claude Code gets to "tell Claude to install it." There is no shipped "install from URL by message" mechanism — bootstrap requires either `/plugin marketplace add` or a curl-bash script. "openclaw" is a third-party CLI proxy, not an Anthropic primitive — don't mimic it.

2. **`/plugin install` only delivers plugin contents to the cache; it does NOT lay down `.orca/`, `orca-context/`, hooks, or settings in the project tree.** A separate `/orca-install` skill (delivered via the plugin) must do the project-tree work. This is two distinct layers and the architect must design both.

3. **The current `install.sh` has no upgrade-vs-fresh distinction, no rename migration, no stale-file pruning, and never wires the settings template.** The new flow is not a rewrite of `install.sh` as a skill — it's a redesign that adds three branches (fresh/upgrade/migrate), a settings prompt, and pruning, while preserving `install.sh`'s framework-vs-user file model.

## Blocker for the architect

**Decision #1 above (plugin-scope vs project-scope skills) is load-bearing for the entire design** and there is no obviously-right answer. Plugin scope gives the "single instruction" UX the PRD is asking for, but changes the install topology (skills no longer in the user's repo). Project scope preserves today's behavior but means we can't get below the current N-step install. The architect should resolve this *before* drafting the install flow, because every subsequent decision (where install logic lives, whether `.orca/` is needed, how upgrades work) cascades from it.

---

## Files written by this task

- `/workspace/orca-context/tasks/006-modes-and-multisession/006/exploration.md` (this file). Uncommitted, for the architect.
