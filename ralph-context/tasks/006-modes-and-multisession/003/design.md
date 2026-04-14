# Task 003 — Multi-session support (architect design)

## Problem recap

Two failure modes today:

1. **Terminal hijack.** `ralph-start.sh /path/to/proj` in terminal B runs `docker start -ai ralph-<folder>` on the same container terminal A already owns, yanking the TTY.
2. **Git collisions.** Two `ralph-loop.sh` runs against the same working tree step on each other (same branch checked out, same staging area, overlapping commits/rebases).

Docker exec fixes (1). Git isolation fixes (2). Both need small, obvious script additions — no new subsystems.

## One-paragraph explanation

A Ralph session is just `<container, working-tree>`. To run a second session against the same project, give it its own working tree and its own container name. For bind-mount mode (`ralph-start.sh`), the user creates a git worktree on the host (`git worktree add ../proj-b ralph/prd-b`) and points `ralph-start.sh` at it — the folder name drives the container name, so isolation is automatic. For volume mode (`ralph-clone.sh`), pass `--session <name>` and a separate container + volume is created (a fresh clone). Attaching a new terminal to any live container uses `ralph-attach.sh <container>`, which runs `docker exec -it`. That's it: worktrees for bind-mount, separate clones for volume-backed, `exec` for extra terminals.

## Chosen mechanism

| Session launcher today  | Multi-session approach        | Rationale                                                                   |
| ----------------------- | ----------------------------- | --------------------------------------------------------------------------- |
| `ralph-start.sh` (bind) | **git worktree on host**      | Host-side `.git` stays shared; each worktree is a normal directory; zero Docker changes beyond a different mount. Worktrees work fine here because the host path IS the container path (`/workspace`), so the absolute paths inside `.git/worktrees/*/gitdir` resolve from the host where the user runs git, not from the container. The container only ever sees its own mount. |
| `ralph-clone.sh` (volume) | **separate clone per session (new volume)** | Worktrees inside a volume would need the parent worktree to also be in a volume and mounted, which is the complication the research doc flagged. Separate volumes are the same pattern Symphony uses and are trivial to reason about: one session = one volume = one clone = one container. |
| Extra terminal on a live session | **`docker exec -it <name> bash`** | Standard Docker. No reattach, no TTY contention. |

### Why not worktrees for the volume case too

Worktrees share one `.git` directory. Inside a Docker volume that's fine in theory, but the user runs `git worktree add` from... where? Not the host (volume isn't mounted there), and not a container (which container owns the primary worktree?). It collapses into a tutorial problem. A second clone costs disk we don't care about and removes the question entirely.

### Why not one container, two worktrees

Same container = same `claude` process state, same home dir, same `/workspace`. Nothing technically stops two `ralph-loop.sh` running inside one container on two sub-directories, but the mental model fragments (which session owns the container? what does `ralph-reset.sh` kill?) and there's no ergonomic win. One session per container is the clean invariant.

## User-facing workflow

### Bind-mount (typical dev-on-laptop case)

Terminal A (already running):
```
./ralph-start.sh ~/code/myproj
# container: ralph-myproj, branch: ralph/prd-a
```

Terminal B (wants to run PRD B in parallel):
```
cd ~/code/myproj
git worktree add ../myproj-prdb ralph/prd-b
./ralph-start.sh ~/code/myproj-prdb
# container: ralph-myproj-prdb, branch: ralph/prd-b
```

When done:
```
# inside container B: exit
docker rm ralph-myproj-prdb
cd ~/code/myproj && git worktree remove ../myproj-prdb
```

### Volume-mode (clone-in-Docker case)

Terminal A:
```
./ralph-clone.sh https://github.com/me/proj.git
# container: ralph-proj, volume: ralph-vol-proj
```

Terminal B:
```
./ralph-clone.sh https://github.com/me/proj.git --session prdb
# container: ralph-proj-prdb, volume: ralph-vol-proj-prdb
```

### Attaching a new terminal to a running session

Either launcher, any terminal:
```
./ralph-attach.sh ralph-myproj
# equivalent to: docker exec -it ralph-myproj bash
```

This is the "I want a second shell on the same session to tail logs" case. It does NOT create a new Ralph session — it's just another TTY on the same container.

## Script changes

### `ralph-start.sh` — minimal change

Current behavior already derives container name from folder basename, so pointing at a different worktree directory already yields a different container. One real bug to fix: when the container already exists, it does `docker start -ai`, which hijacks if another TTY is attached. Change the resume branch to:

```
if container is running:
    exec into it (docker exec -it ... bash)
else:
    docker start -ai ...
```

That makes `ralph-start.sh` safe to re-invoke from a second terminal on the same session without flipping a flag — it "does the right thing" either way.

No worktree logic in the script itself. Worktree creation is a host-side git operation the user runs once; documenting it in `README.md` / install flow is sufficient. Baking `git worktree` into the launcher would couple it to the host's git layout and fail for non-git-worktree setups.

### `ralph-clone.sh` — add `--session` flag

Accept an optional `--session <name>` (or `-s <name>`). When present:

- `CONTAINER_NAME=ralph-${REPO_NAME}-${SESSION}`
- `VOLUME_NAME=ralph-vol-${REPO_NAME}-${SESSION}`

Everything else unchanged. Resume path same correctness fix as `ralph-start.sh` (exec if running, else start -ai).

### New: `ralph-attach.sh`

Tiny wrapper:

```
#!/bin/bash
# Usage: ralph-attach.sh <container-name>
# Opens a new shell in a running Ralph container.
NAME="${1:?usage: ralph-attach.sh <container-name>}"
exec docker exec -it "$NAME" bash
```

Why a script rather than "just tell users to run docker exec": discoverability. It sits next to the other `ralph-*.sh` scripts, `ralph-reset.sh` already lists containers by prefix, and users don't need to remember `-it` or the bash entrypoint.

### `ralph-reset.sh` — no functional change

Already does the right thing (removes one container by name). It should keep working; since each session has its own container, resetting one doesn't touch another.

### `ralph-loop.sh` / `ralph-once.sh` — no change

They operate inside the container on `/workspace`. With per-session working trees, there is nothing to change. They inherit correctness from session-level isolation.

### Documentation

One short section in `README.md` titled "Running multiple sessions" that spells out the two flows above. This is essential — the design's simplicity only lands if the doc exists. Design principle P8 applies: keep it to ~20 lines with a real example, not a tutorial.

## Verification strategy

The PRD's verification ("start two sessions, run different PRDs, both complete, no git conflicts, no TTY hijack, <2min setup") is right. Concretely, the implementer should be able to:

1. **Bind-mount isolation.** In a scratch repo: `git worktree add ../scratch-b somebranch`. Run `ralph-start.sh scratch` in terminal A and `ralph-start.sh scratch-b` in terminal B. Verify both containers are alive (`docker ps` shows two), terminal A is unaffected when B starts, each container sees its own branch (`git branch --show-current` differs). Make a commit in each; no interference.

2. **Volume isolation.** `ralph-clone.sh <url>` then `ralph-clone.sh <url> --session b`. Two volumes exist (`docker volume ls | grep ralph-vol`). Each container has its own clone (different file if you `touch` in one).

3. **Attach doesn't hijack.** With session A running `ralph-loop.sh`, run `ralph-attach.sh ralph-<name>` from a second terminal. Both TTYs work. Exit the attached shell; the loop keeps running.

4. **Re-invoke safety.** With session A's container running, run `ralph-start.sh <same-path>` again from terminal B. It should exec-attach, not hijack the original TTY.

5. **End-to-end.** Two small PRDs, two sessions, `/ralph` in each. Both complete. No merge conflicts because they touch different files (PRD author's responsibility, not the infra's — but worth confirming the infra doesn't introduce false ones).

No automated test infrastructure exists for shell scripts in this repo, and adding one for this is disproportionate. Manual verification against the five cases above is the right bar. The implementer should record results in `ralph-context/tasks/006-modes-and-multisession/003/verification.md`.

## What is explicitly out of scope

- Cross-session orchestration (a "meta-Ralph" dispatching sessions). That's the parallel-agents PRD territory.
- Auto-creating worktrees from the launcher. Couples infra to a specific git workflow; better left to the user.
- A session registry / discovery service. `docker ps | grep ralph-` is sufficient.
- Merge coordination between sessions. Each session pushes its own PR; GitHub is the merge point. Unchanged from today.

## Handoff note to implementer

Three files change, one file added, one doc section added. Keep the diffs small. The safety-of-resume fix in `ralph-start.sh` / `ralph-clone.sh` (exec-if-running vs start-ai) is the only behavior change to the existing scripts; everything else is additive (new flag, new script). Don't rename anything — task 005 handles the `ralph-*` → `orca-*` rename later.
