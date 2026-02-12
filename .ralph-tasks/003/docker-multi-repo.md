# Docker Multi-Repo Design Challenge

## Current State
- `ralph-start.sh` mounts ONE project: `-v "$PROJECT_PATH:/workspace"`
- Container name is derived from project folder: `ralph-$FOLDER_NAME`
- `node_modules` gets its own Docker volume per project
- The assumption is one container = one repo

## Desired State
- Ralph orchestrates across MULTIPLE project repos
- A single Docker container can access multiple projects
- The framework itself (this repo) coexists with target projects
- Principles should remain pure enough for eventual cloud deployment (no Docker-specific coupling)

## Design Constraints
- Nicole only runs `--dangerously-skip-permissions` inside Docker
- Docker container must still provide isolation
- Multiple project mounts need distinct paths inside the container
- Each project may have its own `.ralph/` install and CLAUDE.md

## Open Questions
- How should multiple projects be mounted? Multiple `-v` flags? A workspace root?
- Should the framework repo itself be mounted alongside, or does .ralph/ handle that?
- How does Ralph's task dispatching work across repos? One PRD per repo, or cross-repo PRDs?
- What about node_modules volumes for multiple projects?

## Non-Goals (for now)
- Cloud deployment (keep principles compatible, but don't build cloud infra yet)
- Kubernetes/container orchestration
- Multiple simultaneous Claude sessions
