# Ralph Technique: Complete Step-by-Step Setup Guide

**Time Budget:**
- Machine setup (one-time): ~60 minutes
- Project setup: ~15 minutes  
- Sprint planning: ~15 minutes
- Feature planning: ~5 minutes each
- Human verification: ~15 minutes

**Your Stack:** macOS, Claude Max, React Router, TypeScript, npm, Jest, Figma screenshots

---

## Repository Structure

This repo contains everything you need to run the Ralph workflow. Here's what each file and directory is for:

```
├── README.md                    # This guide - setup and workflow documentation
├── RALPH_PROMPT.md              # Instructions Claude reads each iteration
├── Dockerfile                   # Docker image definition for Ralph containers
├── progress.txt                 # Work log (example/placeholder)
│
├── ralph-start.sh               # Launch container with local project mounted
├── ralph-clone.sh               # Clone a repo into Docker-managed storage
├── ralph-once.sh                # Run single Claude iteration (for testing)
├── ralph-loop.sh                # Run Claude in a loop until done
├── ralph-reset.sh               # Remove a container to start fresh
│
├── templates/                   # Files users copy to their projects
│   ├── CLAUDE.md.template       # Project context template (rename to CLAUDE.md)
│   ├── progress.txt.template    # Initial progress log
│   ├── UI_TESTING.md            # UI testing standards (reference for UI projects)
│   ├── .claudeignore            # File exclusion patterns for Claude
│   └── .git-hooks/
│       └── pre-push             # Git safety hook (blocks pushes to main)
│
├── prds/                        # PRD templates and tools
│   ├── PRD_TEMPLATE.json        # Template for creating new PRDs
│   ├── PRD_REFINE.md            # Prompt for refining PRDs
│   └── new-prd.sh               # Helper script to create numbered PRDs
│
└── ralph-logs/                  # Iteration logs (gitignored, local only)
```

**Key distinction:**
- **Machine-level scripts** (`ralph-start.sh`, `ralph-clone.sh`, `ralph-reset.sh`, `Dockerfile`) are installed once in `~/ralph-docker/` and manage containers
- **Project-level scripts** (`ralph-once.sh`, `ralph-loop.sh`) are copied into each project and run inside containers
- **Templates** (`templates/`) are copied into each project you want to use Ralph with
- **PRD tools** (`prds/`) can be copied to projects or used from this repo directly

---

## Part 1: One-Time Machine Setup (~60 minutes)

### Step 1.1: Install Docker Desktop (10 min)

1. Download Docker Desktop for Mac from https://www.docker.com/products/docker-desktop/
2. Open the `.dmg` and drag Docker to Applications
3. Launch Docker Desktop
4. Wait for the whale icon in menu bar to show "Docker Desktop is running"
5. **Configure resources:** Click whale icon → Settings → Resources → Set Memory to 8GB+, CPUs to 4+
6. Verify in Terminal:
   ```bash
   docker --version
   ```

### Step 1.2: Install Claude Code (5 min)

```bash
curl -fsSL https://claude.ai/install.sh | bash
# Restart terminal, then:
claude --version
```

### Step 1.3: Authenticate Claude Code with Claude Max (5 min)

```bash
claude
# Choose "Claude.ai account (Pro/Max subscription)"
# Browser opens - log in with your Claude Max account
# Return to terminal after authentication completes
```

**Do this BEFORE setting up Docker.** Your auth will be shared with containers automatically.

### Step 1.4: Configure Git Authentication

**If using Git Credential Manager (GCM) via HTTPS** (check with `git config --get credential.helper`):

You're already set. Skip SSH key setup entirely. Your `.gitconfig` will be mounted into the container.

**If using SSH keys** (or want to set them up):

```bash
# Check for existing key
ls ~/.ssh/id_ed25519.pub 2>/dev/null || ls ~/.ssh/id_rsa.pub 2>/dev/null

# If no output, create one:
ssh-keygen -t ed25519 -C "your-email@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Add to GitHub:
pbcopy < ~/.ssh/id_ed25519.pub
# GitHub → Settings → SSH and GPG keys → New SSH key → Paste

# Test:
ssh -T git@github.com
```

### Step 1.5: Configure Git Identity (2 min)

```bash
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"
```

### Step 1.6: Create the Ralph Docker Image (15 min)

This custom image provides: persistent containers that survive restarts (critical for resuming Ralph), Playwright pre-installed for UI testing, and full control over the environment.

```bash
mkdir -p ~/ralph-docker
cd ~/ralph-docker
```

Copy the [Dockerfile](Dockerfile) from this repository:
```bash
cp ~/ralph/Dockerfile .
```

The Dockerfile installs: Node.js 20, GitHub CLI (`gh`), Git, development tools (ripgrep, fd-find, jq, tree), Playwright with Chromium, and Claude Code. It configures commits as `claude-bot`.

Build (takes ~10 min due to Playwright):
```bash
docker build -t ralph-claude:latest .
```

### Step 1.7: Install Ralph Helper Scripts (10 min)

Clone this Ralph repository and copy the machine-level scripts to your ralph-docker directory:

```bash
# Clone the Ralph repo if you haven't already
git clone https://github.com/your-org/ralph.git ~/ralph

# Copy machine-level scripts to ralph-docker
cp ~/ralph/ralph-start.sh ~/ralph/ralph-clone.sh ~/ralph/ralph-reset.sh ~/ralph-docker/
chmod +x ~/ralph-docker/*.sh
```

**Note:** `ralph-once.sh` and `ralph-loop.sh` run inside containers, so they get copied to each project in Part 3, not to `~/ralph-docker/`.

**What each script does:**

| Script | Location | Purpose |
|--------|----------|---------|
| [ralph-start.sh](ralph-start.sh) | `~/ralph-docker/` | Launch a container with a local project folder mounted |
| [ralph-clone.sh](ralph-clone.sh) | `~/ralph-docker/` | Clone a repo into Docker-managed storage |
| [ralph-reset.sh](ralph-reset.sh) | `~/ralph-docker/` | Remove a container to start fresh |
| [ralph-once.sh](ralph-once.sh) | Your project | Run a single Claude iteration (for testing) |
| [ralph-loop.sh](ralph-loop.sh) | Your project | Run Claude in a loop until done or max iterations |

**Key notes:**
- **Machine-level scripts** (`ralph-start.sh`, `ralph-clone.sh`, `ralph-reset.sh`) go in `~/ralph-docker/` and run on your Mac
- **Project-level scripts** (`ralph-once.sh`, `ralph-loop.sh`) get copied to each project and run inside containers
- `node_modules` uses a named Docker volume (Mac/Linux architecture differences)
- Run `npm install` inside the container on first use

### Step 1.8: Add Scripts to PATH (1 min)

```bash
echo 'export PATH="$HOME/ralph-docker:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**Note on Playwright:** If your project needs UI/E2E testing with Playwright, you'll set that up as part of your project's test infrastructure (Part 4), not as a Ralph requirement. The Docker container has Playwright browsers pre-installed for when you need them.

---

## Part 2: GitHub Branch Protection (10 min, one-time per repo)

This is your bulletproof safeguard. Even if Claude tries to push to main, GitHub will reject it.

### Step 2.1: Enable Branch Protection

1. Go to your repo on GitHub
2. **Settings** → **Branches** (left sidebar)
3. Click **Add branch protection rule**
4. Branch name pattern: `main`
5. Enable these settings:
   - ✅ **Require a pull request before merging**
   - ✅ **Require approvals** → Set to **1**
   - ✅ **Do not allow bypassing the above settings**
6. Click **Create** / **Save changes**

### Step 2.2: Your Workflow (Human)

When YOU want to push to main:
```bash
git checkout -b my-feature
# ... make changes ...
git push -u origin my-feature
# Go to GitHub → Create PR → Approve your own PR → Merge
```

### Step 2.3: Claude's Workflow (Automated)

Claude will:
1. Create a feature branch at the start
2. Make commits to that branch
3. Push the branch when done
4. Stop and tell you to review the PR

You then: Review on GitHub → Approve → Merge → Delete branch

---

## Part 3: Project Setup (~15 minutes per project)

These files go in your project root (or subdirectories as specified). Repeat this setup for each project you want to use with Ralph.

### Step 3.0: Clone This Repository

If you haven't already, clone this Ralph repository to your machine:

```bash
git clone https://github.com/your-org/ralph.git ~/ralph
```

This gives you access to all templates and scripts. The setup steps below copy files from `~/ralph/` to your project.

### Step 3.1: Navigate to Your Project

```bash
cd /path/to/your/project
```

Or if using the clone workflow, you'll run `ralph-clone.sh` later instead.

### Step 3.2: Install the Git Safety Hook

This blocks dangerous git commands inside the container as a safety net (branch protection is the real safeguard, this is defense in depth).

Copy from the Ralph repo and configure git to use it:

```bash
mkdir -p .git-hooks
cp ~/ralph/templates/.git-hooks/pre-push .git-hooks/pre-push
chmod +x .git-hooks/pre-push
git config core.hooksPath .git-hooks
```

See [templates/.git-hooks/pre-push](templates/.git-hooks/pre-push) for the hook source.

Commit the hook:
```bash
git add .git-hooks
git commit -m "Add git safety hook to block direct pushes to main"
```

### Step 3.3: Create Minimal CLAUDE.md Base

Start with a minimal template. Claude will expand this by exploring your project.

Copy from the Ralph repo:
```bash
cp ~/ralph/templates/CLAUDE.md.template ./CLAUDE.md
```

See [templates/CLAUDE.md.template](templates/CLAUDE.md.template) for the starting point.

### Step 3.4: Copy Claude Code Skills

Copy the skills directory from the Ralph repo:

```bash
mkdir -p .claude/skills
cp -r ~/ralph/.claude/skills/* .claude/skills/
```

This installs the `/discover` skill used in the next step. See [.claude/skills/discover/SKILL.md](.claude/skills/discover/SKILL.md) for the skill definition.

### Step 3.5: Run Project Discovery

Have Claude explore your project and complete CLAUDE.md with actual details.

```bash
cd /path/to/your/project
claude
```

Run the discover skill:

```
/discover
```

This explores your project and populates CLAUDE.md with tech stack, project structure, coding patterns, testing setup, and dev server details.

Review the output and adjust anything that seems wrong.

### Step 3.6: Copy RALPH_PROMPT.md

This is what Claude reads each iteration. The PRD filename is passed when invoking the script.

Copy from the Ralph repo:
```bash
cp ~/ralph/RALPH_PROMPT.md ./RALPH_PROMPT.md
```

See [RALPH_PROMPT.md](RALPH_PROMPT.md) for the full instructions Claude follows during each iteration.

### Step 3.7: Create PRD Directory and Template

PRDs are numbered for history (e.g., `001_initial_setup.json`, `002_user_auth.json`). **Task IDs are for reference only—they do NOT imply execution order.** Ralph picks the best next task dynamically.

Copy from the Ralph repo:
```bash
mkdir -p prds
cp ~/ralph/prds/PRD_TEMPLATE.json ./prds/
cp ~/ralph/prds/new-prd.sh ./prds/
chmod +x prds/new-prd.sh
```

See [prds/PRD_TEMPLATE.json](prds/PRD_TEMPLATE.json) for the template structure and [prds/new-prd.sh](prds/new-prd.sh) for the helper script.

**Workflow:**
1. `./prds/new-prd.sh "user authentication"` → creates `prds/001_user_authentication.json`
2. Edit the PRD file with your tasks
3. Run Ralph: `./ralph-loop.sh prds/001_user_authentication.json`
4. When done, the numbered file serves as history

### Step 3.8: Create progress.txt

Copy from the Ralph repo:
```bash
cp ~/ralph/templates/progress.txt.template ./progress.txt
```

See [templates/progress.txt.template](templates/progress.txt.template) for the initial structure.

### Step 3.9: Copy UI_TESTING.md (Reference for UI Projects)

This file contains UI testing standards. Claude reads it when working on UI tasks.

Copy from the Ralph repo:
```bash
cp ~/ralph/templates/UI_TESTING.md .
```

The file defines accessibility-first testing standards: semantic HTML, ARIA attributes for interactive elements, and using Playwright's accessibility snapshots to verify UI correctness. See [templates/UI_TESTING.md](templates/UI_TESTING.md) for the full document.

### Step 3.10: Copy PRD_REFINE.md (PRD Quality Check)

This prompt helps refine PRDs to ensure tasks are right-sized.

Copy from the Ralph repo:
```bash
cp ~/ralph/prds/PRD_REFINE.md ./prds/PRD_REFINE.md
```

See [prds/PRD_REFINE.md](prds/PRD_REFINE.md) for the full PRD refinement checklist.

### Step 3.11: Copy Ralph Scripts to Project Root

Copy the in-container scripts from the Ralph repo to your project root:

```bash
cp ~/ralph/ralph-loop.sh ./ralph-loop.sh
cp ~/ralph/ralph-once.sh ./ralph-once.sh
chmod +x ralph-loop.sh ralph-once.sh
```

See [ralph-loop.sh](ralph-loop.sh) and [ralph-once.sh](ralph-once.sh) for the current versions.

### Step 3.12: Update .gitignore

```bash
cat >> .gitignore << 'EOF'

# Ralph logs (iteration transcripts for debugging)
ralph-logs/
EOF
```

### Step 3.13: Create .claudeignore

Prevent Claude from reading sensitive or wasteful files. Claude Code doesn't do RAG on large files—it reads them into context, which wastes tokens and can hit limits.

Copy from the Ralph repo:
```bash
cp ~/ralph/templates/.claudeignore ./.claudeignore
```

See [templates/.claudeignore](templates/.claudeignore) for the default exclusions.

**Customize for your project:** Review what's in your `.gitignore`—most of those should also be in `.claudeignore`. The key categories:
- **Secrets** — Always ignore
- **Generated/compiled** — Ignore (Claude can read source files)
- **Dependencies** — Always ignore (`node_modules` is massive)
- **Test artifacts** — Usually ignore (reports, screenshots)
- **Ralph logs** — Optional (might help debugging, but large)

### Step 3.14: Commit Setup

```bash
git add CLAUDE.md RALPH_PROMPT.md UI_TESTING.md prds/ progress.txt ralph-loop.sh ralph-once.sh .git-hooks .gitignore .claudeignore .claude/
git commit -m "Add Ralph workflow configuration"
git push
```

---

## Part 4: Test Infrastructure PRD (Your First Ralph Run)

Your first PRD gets your test infrastructure ready. Task 001 is always "fix existing tests"—everything else builds on that.

### Step 4.1: Quick Assessment

On your Mac:
```bash
cd /path/to/your/project
claude
```

```
Run `npm test` and tell me:
1. Do tests pass, fail, or error out entirely?
2. What test framework is configured?
3. Roughly how many tests exist?
```

### Step 4.2: Generate Initial PRD

```bash
./prds/new-prd.sh "test infrastructure"
```

Then in Claude:

```
Create a PRD for test infrastructure setup.

Current state: [Paste assessment from Step 4.1]

Requirements:
- Task 001 MUST be "Fix existing tests" 
  Acceptance: "npm test runs and all existing tests pass"
- Add tasks for any test infrastructure improvements needed
- Reference UI_TESTING.md for UI testing standards if relevant

Output valid JSON matching prds/PRD_TEMPLATE.json
```

### Step 4.3: Refine the PRD

```
Read prds/PRD_REFINE.md and use it to review the PRD above
```

Apply any changes, run again if needed. Usually 1-2 passes.

### Step 4.4: Save and Run

```bash
# Save final PRD to prds/001_test_infrastructure.json
git add prds/
git commit -m "Add test infrastructure PRD"
git push

# Start the container
ralph-start.sh /path/to/your/project
```

**First run only:** Set up GitHub access:

```bash
# Login to GitHub
gh auth login
# Choose: GitHub.com → HTTPS → Yes (authenticate git) → Login with browser
# Copy the code, open the URL in your browser manually, paste code

# Configure git to use gh for credentials
gh auth setup-git

# Verify
git fetch
```

**Note:** Git user is pre-configured as `claude-bot`. Credentials persist in the container between restarts — you only need to do this once per container (or after `--fresh`).

Now run Ralph:
```bash
./ralph-once.sh prds/001_test_infrastructure.json        # Test single iteration
./ralph-loop.sh prds/001_test_infrastructure.json 20     # Run the full loop
```

### Step 4.5: External Dependencies (If Needed)

If tests need external services (database, etc.), add to your initial prompt:

```
Also note any external dependencies:
- What services do tests need to run?
- What commands should I run before starting Ralph?
```

---

## Part 5: Feature Planning (For Each Sprint)

After your test infrastructure PRD is complete, use this process for feature work.

### Step 5.1: Create a New PRD

```bash
cd /path/to/your/project
./prds/new-prd.sh "feature name"
```

### Step 5.2: Generate Initial PRD

```bash
claude
```

Describe what you want to build:

```
I want to build [describe your features in plain language].

Create a PRD matching prds/PRD_TEMPLATE.json:
- Break into logical tasks
- Each task completable in one focused session
- Clear acceptance criteria (testable)
- All tasks start with "testsPassing": false

Output valid JSON.
```

### Step 5.3: Refine the PRD

```
Read prds/PRD_REFINE.md and use it to review this PRD
```

Apply any changes, run again if needed. Usually 1-2 passes.

### Step 5.4: Save and Run

```bash
# Save PRD (e.g., prds/002_feature_name.json)
git add prds/
git commit -m "Add feature PRD"

# Run Ralph
./ralph-loop.sh prds/002_feature_name.json 20
```

### Step 5.5: Don't Over-Plan

Ralph picks tasks dynamically and can split tasks or add new ones as needed. You don't need perfect upfront planning—just a reasonable starting point.

---

## Part 6: Feature Planning (~5 min each)

For features needing more detail before Ralph starts:

```
Expand task 003 in prds/002_feature_name.json with:
- More specific acceptance criteria
- Key implementation considerations  
- Test cases that should be written
```

### Using Figma Screenshots

1. Capture: `Cmd+Ctrl+Shift+4` or copy from Figma
2. In Claude: `Ctrl+V` to paste
3. Prompt:
```
Implement this exact design. Clone precisely—no creativity.
Match colors, spacing, typography exactly.
Use Tailwind. Make responsive.
```

---

## Part 7: Running Ralph

### Option A: Local Project (Mounted Folder)

```bash
ralph-start.sh /path/to/your/project
```

### Option B: Repo Clone (Docker-Managed)

```bash
ralph-clone.sh https://github.com/your-username/your-repo.git
```

### Inside the Container

```bash
# Verify setup
git status
npm test
```

### Test with Single Iteration First

Before running the full loop, verify everything works:

```bash
./ralph-once.sh
```

Watch what Claude does. Check that it:
- Reads the PRD correctly
- Creates/uses a feature branch
- Makes sensible changes
- Runs tests and they pass
- Commits properly

If something's wrong, fix your CLAUDE.md or RALPH_PROMPT.md and try again.

### Dry Run Test (No Git Commits)

To test your Ralph setup without making any real changes to your codebase, use the dry run PRD. This is useful when:
- Setting up Ralph for the first time
- Verifying the loop mechanics work after configuration changes
- Testing in a new environment

```bash
./ralph-loop.sh prds/999_dry_run_test.json
```

The dry run PRD contains tasks that only edit the PRD file itself—no git commits, no code changes. Claude will cycle through 5 simple tasks, flipping `testsPassing` flags. When complete, you'll see the `<promise>COMPLETE</promise>` signal.

**What success looks like:**
- Ralph runs through all 5 iterations without errors
- The PRD file shows all tasks with `testsPassing: true`
- No git commits were made
- The COMPLETE signal appears

**To reset for another test run:**
```bash
# Reset all tasks to testsPassing: false
# (Edit prds/999_dry_run_test.json or copy fresh from Ralph repo)
```

### Run the Full Loop

```bash
# Run up to 20 iterations (exits early on COMPLETE signal)
./ralph-loop.sh 20

# Or more iterations for overnight runs
./ralph-loop.sh 50
```

### Monitor (Separate Terminal on Mac)

```bash
cd /path/to/project
tail -f progress.txt
watch -n 5 'git log --oneline -10'
```

### Stop Ralph

- **Graceful:** Wait for iteration to finish, then `Ctrl+C`
- **Immediate:** `Ctrl+C` twice
- **Automatic:** Claude outputs `<promise>COMPLETE</promise>` when all tasks done

### Exit Container

```bash
exit
# Container pauses but preserves state
```

### Resume Later

```bash
ralph-start.sh /path/to/project  # Or ralph-clone.sh URL
./ralph-loop.sh 20
```

---

## Part 8: Human Verification (~15 min)

### Step 8.1: Review Progress

```bash
cat progress.txt
```

Check for blocked tasks needing attention.

### Step 8.2: Review Commits

```bash
git log --oneline -20
# Or on GitHub, view the branch's commit history
```

### Step 8.3: Run Tests

```bash
npm test
```

### Step 8.4: Manual Testing

```bash
npm run dev
# Test in browser
```

### Step 8.5: Review and Merge PR

1. Go to GitHub → Pull Requests
2. Review Claude's PR
3. Check the diff, commits
4. Approve and merge
5. Delete the branch

### Step 8.6: Pull Merged Changes

```bash
git checkout main
git pull
```

---

## Part 9: Troubleshooting

### Git Push Fails

```bash
# Inside container
git fetch
git rebase origin/main
git push
```

### Tests Keep Failing

```bash
# Exit loop (Ctrl+C)
npm test  # See full output
# Fix manually or ask Claude interactively
```

### Container Corrupted

```bash
# On Mac
ralph-reset.sh ralph-your-project
ralph-start.sh /path/to/project
```

### Claude Not Authenticated

```bash
# Inside container
claude auth status
claude auth login
```

### Rate Limited

Wait for reset, reduce iterations, or switch model:
```bash
# Inside Claude session
/model sonnet
```

---

## Quick Reference

### Daily Workflow

**Step 1: Create PRD (~10 min)**

```bash
cd ~/projects/my-app
./prds/new-prd.sh "feature name"
claude
```

```
I want to build [describe your features].

Create a PRD matching prds/PRD_TEMPLATE.json:
- Break into logical tasks
- Each task completable in one focused session
- Clear acceptance criteria (testable)
- All tasks start with "testsPassing": false

Output valid JSON.
```

Refine if needed (see Part 5), save to PRD file.

**Step 2: Run Ralph**

```bash
ralph-start.sh ~/projects/my-app

# Inside container:
./ralph-once.sh prds/002_feature_name.json           # Test single iteration
./ralph-loop.sh prds/002_feature_name.json 30        # Run full loop
exit
```

**Step 3: Review and Merge**

On GitHub: Review PR → Check commits → Approve → Merge

```bash
git checkout main && git pull
```

### Key Files

**Machine-level (one-time setup in `~/ralph-docker/`):**

| File | Purpose | Source |
|------|---------|--------|
| `Dockerfile` | Builds Ralph Docker image | Copy from Ralph repo |
| `ralph-start.sh` | Start container with local folder | Created via README heredoc |
| `ralph-clone.sh` | Start container with cloned repo | Created via README heredoc |
| `ralph-reset.sh` | Remove container to start fresh | Created via README heredoc |

**Project-level (per-project in project root):**

| File | Purpose | Source |
|------|---------|--------|
| `CLAUDE.md` | Project context | Create via README heredoc, then run discovery |
| `RALPH_PROMPT.md` | Loop instructions for Claude | Create via README heredoc |
| `UI_TESTING.md` | UI testing standards (optional) | Copy from Ralph repo `templates/` |
| `prds/PRD_TEMPLATE.json` | Template for new PRDs | Create via README heredoc |
| `prds/PRD_REFINE.md` | PRD quality check prompt | Create via README heredoc |
| `prds/new-prd.sh` | Helper to create numbered PRDs | Create via README heredoc |
| `ralph-loop.sh` | Run Ralph iterations | Copy from `~/ralph-docker/` |
| `ralph-once.sh` | Run single iteration (testing) | Copy from `~/ralph-docker/` |
| `progress.txt` | Work log | Create via README heredoc |
| `.git-hooks/pre-push` | Block pushes to main | Create via README heredoc |
| `.claudeignore` | Hide files from Claude | Create via README heredoc |

### Commands

| Command | What it does |
|---------|--------------|
| `./prds/new-prd.sh "name"` | Create a new numbered PRD |
| `ralph-start.sh /path` | Start container with local folder mounted |
| `ralph-start.sh --fresh /path` | Recreate container (after image rebuild) |
| `ralph-clone.sh URL` | Start container with repo cloned into Docker storage |
| `ralph-reset.sh name` | Delete container and volume completely |
| `./ralph-once.sh <prd>` | Run single iteration (for testing) |
| `./ralph-loop.sh <prd> [N]` | Run up to N iterations (default 20) |

### Rate Limits (Claude Max)

With Claude Max, you pay a flat subscription—no per-token costs. Instead, you hit rate limits:

| Plan | Approximate Capacity |
|------|---------------------|
| Max 5x ($100/mo) | ~50-200 messages per 5-hour window |
| Max 20x ($200/mo) | ~200-800 messages per 5-hour window |

A 30-iteration Ralph loop may use a significant portion of your quota. If rate-limited, wait for the window to reset or reduce iterations. The `<promise>COMPLETE</promise>` signal helps by exiting early when done.

---

## Troubleshooting

### Container Issues

**Container seems corrupted or stuck:**
```bash
ralph-reset.sh ralph-myproject
ralph-start.sh /path/to/myproject
```
This deletes the container but NOT your files. Safe to do anytime.

**Can't push to GitHub from container:**
- Check SSH: `ssh -T git@github.com` (should show your username)
- Check your `~/.ssh` is mounted correctly
- For HTTPS: Check that Git Credential Manager is working on your Mac first

**Claude not authenticated:**
```bash
claude auth status   # Check current status
claude auth login    # Re-authenticate if needed
```

### Ralph Loop Issues

**Ralph keeps failing on the same task:**
- Check `progress.txt` for error patterns
- Run `./ralph-once.sh prds/your_prd.json` to see full output
- The prompt says to mark as `blocked` after 3 attempts, but Claude might not always follow this

**Tests keep failing:**
- Exit the loop (Ctrl+C)
- Run tests manually: `npm test`
- Fix interactively with Claude, then resume

**Ralph never outputs COMPLETE:**
- Check your PRD file—are there tasks with `testsPassing: false`?
- Check if any tasks are stuck (same task attempted multiple times in progress.txt)
- Reduce max iterations and investigate

### Script Issues

**"Permission denied" when running scripts:**
```bash
chmod +x ~/ralph-docker/*.sh
chmod +x ./ralph-loop.sh ./ralph-once.sh
```

**Script not found:**
```bash
# Check PATH includes ralph-docker
echo $PATH | grep ralph-docker

# If not, add it
echo 'export PATH="$HOME/ralph-docker:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

---

## Summary

**Safeguards in place:**
- GitHub branch protection blocks pushes to main
- Git hook blocks pushes to main (backup)
- Prompt instructions (guidance)
- Container isolation (can't touch rest of your Mac)

**Claude commits as:** `claude-bot <claude-bot@users.noreply.github.com>`

**Workflow:**
1. You write PRD with tasks
2. Ralph works on feature branch, commits as it goes
3. Ralph pushes branch when done
4. You review PR, approve, merge

**Key insight:** Ralph's power is the feedback loop—tests verify code, git preserves progress, PRD checklist knows when to stop. You define the end state. Ralph gets there.

---

## Appendix A: Playwright Reference

This supplements `UI_TESTING.md` with Playwright-specific details. Only relevant if your test planning identifies Playwright as the right tool.

### What Playwright Provides

- Browser automation (Chromium pre-installed in container)
- **Accessibility snapshots**: Structured view of how screen readers see the page
- MCP integration for Claude to interact with browsers directly

### Accessibility Snapshot Example

```yaml
- main:
  - heading "Sign Up" [level=1]
  - textbox "Email" [required]
  - button "Submit" [disabled]
```

This YAML represents the accessibility tree—what our UI_TESTING.md standards help create.

### MCP Setup (If Needed)

If Claude needs to use Playwright MCP during development (not just tests):

```bash
claude mcp add playwright -- npx @playwright/mcp@latest --headless --caps=testing
```

### Key Point

Playwright is a **testing tool**. It runs tests; Ralph runs until tests pass. Claude figures out the specific implementation based on `UI_TESTING.md` standards and your project's test setup.
