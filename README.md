# Ralph Technique: Complete Step-by-Step Setup Guide

**Time Budget:**
- Machine setup (one-time): ~60 minutes
- Project setup: ~15 minutes  
- Sprint planning: ~15 minutes
- Feature planning: ~5 minutes each
- Human verification: ~15 minutes

**Your Stack:** macOS, Claude Max, React Router, TypeScript, npm, Jest, Figma screenshots

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

### Step 1.7: Create Ralph Helper Scripts (10 min)

**ralph-start.sh** — Launches a persistent container for a local project folder. Your Mac's `node_modules` is shadowed by the container's own copy (required because Mac and Linux have different architectures). Run `npm install` inside the container on first use.

```bash
cat > ~/ralph-docker/ralph-start.sh << 'EOF'
#!/bin/bash
# ralph-start.sh - Start Ralph container with local project mounted
# Usage: ralph-start.sh [--fresh] /path/to/project [container-name]
#   --fresh    Remove existing container and create new one
#
# Note: Run `npm install` inside the container - Mac's node_modules won't work.

set -e  # Exit on any error

# Check for --fresh flag
FRESH=false
if [ "$1" = "--fresh" ] || [ "$1" = "-f" ]; then
    FRESH=true
    shift
fi

# Arguments with defaults
PROJECT_PATH="${1:-.}"                                    # Default: current directory

# Convert to absolute path (fails if path doesn't exist)
PROJECT_PATH=$(cd "$PROJECT_PATH" && pwd) || {
    echo "❌ Error: Project path '$1' does not exist"
    exit 1
}

# Get folder name for container (handles trailing slashes and edge cases)
FOLDER_NAME=$(basename "$PROJECT_PATH")
if [ -z "$FOLDER_NAME" ] || [ "$FOLDER_NAME" = "/" ]; then
    FOLDER_NAME="project"
fi
CONTAINER_NAME="${2:-ralph-$FOLDER_NAME}"

echo "🚀 Ralph Container: $CONTAINER_NAME"
echo "📁 Project: $PROJECT_PATH"

# Handle --fresh: remove existing container
if [ "$FRESH" = true ] && docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "🗑️  Removing existing container (--fresh)..."
    docker rm -f "$CONTAINER_NAME"
fi

# Check if container already exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "📦 Resuming existing container..."
    docker start -ai "$CONTAINER_NAME"
else
    echo "📦 Creating new container..."
    docker run -it \
        --name "$CONTAINER_NAME" \
        --memory="8g" \
        --cpus="4" \
        -v "$PROJECT_PATH:/workspace" \
        -v /workspace/node_modules \
        ralph-claude:latest \
        bash
    # -v /workspace/node_modules creates an anonymous volume that shadows
    # Mac's node_modules (different architectures). Run `npm install` inside.
fi
EOF
chmod +x ~/ralph-docker/ralph-start.sh
```

**ralph-clone.sh** — Alternative workflow: clones a repo into Docker-managed storage. You never manage local files—just push/pull via git.

```bash
cat > ~/ralph-docker/ralph-clone.sh << 'EOF'
#!/bin/bash
# ralph-clone.sh - Start Ralph with repo cloned into Docker volume
# Usage: ralph-clone.sh https://github.com/user/repo.git

set -e  # Exit on any error

REPO_URL="$1"
if [ -z "$REPO_URL" ]; then
    echo "Usage: ralph-clone.sh <github-repo-url>"
    echo "Example: ralph-clone.sh https://github.com/user/repo.git"
    exit 1
fi

# Extract repo name from URL (handles .git suffix)
REPO_NAME=$(basename "$REPO_URL" .git)
CONTAINER_NAME="ralph-${REPO_NAME}"
VOLUME_NAME="ralph-vol-${REPO_NAME}"

echo "🚀 Ralph Container: $CONTAINER_NAME"
echo "📦 Volume: $VOLUME_NAME"

# Create Docker volume if it doesn't exist (persists data between container recreations)
if ! docker volume ls -q | grep -q "^${VOLUME_NAME}$"; then
    echo "📦 Creating volume: $VOLUME_NAME"
    docker volume create "$VOLUME_NAME"
fi

# Resume existing container or create new one
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "📦 Resuming existing container..."
    docker start -ai "$CONTAINER_NAME"
else
    echo "📦 Creating container and cloning repo..."
    docker run -it \
        --name "$CONTAINER_NAME" \
        --memory="8g" \
        --cpus="4" \
        -v "${VOLUME_NAME}:/workspace" \
        -v /workspace/node_modules \
        -e "REPO_URL=$REPO_URL" \
        ralph-claude:latest \
        bash -c '
            if [ ! -d ".git" ]; then
                echo "📥 Cloning repository..."
                git clone "$REPO_URL" .
            else
                echo "📂 Repository already cloned"
            fi
            exec bash
        '
    # -v /workspace/node_modules creates an anonymous volume for Linux node_modules
fi
EOF
chmod +x ~/ralph-docker/ralph-clone.sh
```

**ralph-once.sh** — Runs a single Claude iteration. Use this to test your setup before running the full loop.

```bash
cat > ~/ralph-docker/ralph-once.sh << 'EOF'
#!/bin/bash
# ralph-once.sh - Run a single Ralph iteration (for testing)
# Usage: ./ralph-once.sh <prd-file> [prompt-file]
# Run this INSIDE the container, in /workspace
#
# Note: Output is buffered (appears when iteration completes).
# To watch live, open another terminal and run: tail -f ralph-logs/*.log

PRD_FILE="${1:-}"
PROMPT_FILE="${2:-RALPH_PROMPT.md}"

# PRD file is required
if [ -z "$PRD_FILE" ]; then
    echo "❌ Error: PRD file required"
    echo "Usage: ./ralph-once.sh <prd-file> [prompt-file]"
    echo "Example: ./ralph-once.sh prds/001_test_infrastructure.json"
    exit 1
fi

if [ ! -f "$PRD_FILE" ]; then
    echo "❌ Error: PRD file '$PRD_FILE' not found"
    echo "Available PRDs:"
    ls -1 prds/*.json 2>/dev/null | grep -v TEMPLATE || echo "  (none)"
    exit 1
fi

if [ ! -f "$PROMPT_FILE" ]; then
    echo "❌ Error: $PROMPT_FILE not found"
    exit 1
fi

# Create logs directory
mkdir -p ralph-logs

# Get PRD name for log prefix
PRD_NAME=$(basename "$PRD_FILE" .json)
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
LOG_FILE="ralph-logs/${PRD_NAME}_${TIMESTAMP}_once.log"

echo "🔂 Running single Ralph iteration"
echo "📋 Prompt: $PROMPT_FILE"
echo "📝 PRD: $PRD_FILE"
echo "📄 Log: $LOG_FILE"
echo ""
echo "💡 To watch live output, open another terminal and run:"
echo "   tail -f $LOG_FILE"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Log header
{
    echo "=== Ralph Single Iteration ==="
    echo "PRD: $PRD_FILE"
    echo "Started: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "=================================="
    echo ""
} > "$LOG_FILE"

# Run claude in print mode
OUTPUT=$(claude -p "Read $PROMPT_FILE for instructions. The PRD file is: $PRD_FILE" --dangerously-skip-permissions 2>&1)

# Display and log
echo "$OUTPUT"
echo "$OUTPUT" >> "$LOG_FILE"

# Log footer
{
    echo ""
    echo "=================================="
    echo "Finished: $(date '+%Y-%m-%d %H:%M:%S')"
} >> "$LOG_FILE"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Single iteration complete"
echo "📄 Log saved to: $LOG_FILE"
echo "Check git log and progress.txt to see what happened"
EOF
chmod +x ~/ralph-docker/ralph-once.sh
```

**ralph-loop.sh** — Runs Claude repeatedly until it outputs `<promise>COMPLETE</promise>` or hits max iterations.

```bash
cat > ~/ralph-docker/ralph-loop.sh << 'EOF'
#!/bin/bash
# ralph-loop.sh - Run Ralph in a loop until done
# Usage: ./ralph-loop.sh <prd-file> [max-iterations] [prompt-file]
# Run this INSIDE the container, in /workspace
#
# Note: Output is buffered (appears after each iteration completes).
# To watch live, open another terminal and run: tail -f ralph-logs/*.log

PRD_FILE="${1:-}"
MAX_ITERATIONS="${2:-20}"
PROMPT_FILE="${3:-RALPH_PROMPT.md}"

# PRD file is required
if [ -z "$PRD_FILE" ]; then
    echo "❌ Error: PRD file required"
    echo "Usage: ./ralph-loop.sh <prd-file> [max-iterations] [prompt-file]"
    echo "Example: ./ralph-loop.sh prds/001_test_infrastructure.json 20"
    exit 1
fi

if [ ! -f "$PRD_FILE" ]; then
    echo "❌ Error: PRD file '$PRD_FILE' not found"
    echo "Available PRDs:"
    ls -1 prds/*.json 2>/dev/null | grep -v TEMPLATE || echo "  (none)"
    exit 1
fi

if [ ! -f "$PROMPT_FILE" ]; then
    echo "❌ Error: $PROMPT_FILE not found"
    exit 1
fi

# Create logs directory
mkdir -p ralph-logs

# Get PRD name for log prefix (e.g., "001_test_infrastructure" from path)
PRD_NAME=$(basename "$PRD_FILE" .json)
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')

echo "🔄 Ralph Loop Starting"
echo "📋 Prompt: $PROMPT_FILE"
echo "📝 PRD: $PRD_FILE"
echo "🔢 Max iterations: $MAX_ITERATIONS"
echo "📂 Logs: ralph-logs/${PRD_NAME}_${TIMESTAMP}_*.log"
echo ""
echo "💡 To watch live output, open another terminal and run:"
echo "   tail -f ralph-logs/${PRD_NAME}_${TIMESTAMP}_*.log"
echo ""
echo "⏹️  Ctrl+C to stop, or wait for COMPLETE signal"
echo ""

ITERATION=0
while [ $ITERATION -lt $MAX_ITERATIONS ]; do
    ITERATION=$((ITERATION + 1))
    LOG_FILE="ralph-logs/${PRD_NAME}_${TIMESTAMP}_$(printf '%03d' $ITERATION).log"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔁 Iteration $ITERATION of $MAX_ITERATIONS"
    echo "📄 Log: $LOG_FILE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Log header
    {
        echo "=== Ralph Iteration $ITERATION ==="
        echo "PRD: $PRD_FILE"
        echo "Started: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "=================================="
        echo ""
    } > "$LOG_FILE"
    
    # Run claude in print mode (buffered output)
    OUTPUT=$(claude -p "Read $PROMPT_FILE for instructions. The PRD file is: $PRD_FILE" --dangerously-skip-permissions 2>&1)
    
    # Display and log
    echo "$OUTPUT"
    echo "$OUTPUT" >> "$LOG_FILE"
    
    # Log footer
    {
        echo ""
        echo "=================================="
        echo "Finished: $(date '+%Y-%m-%d %H:%M:%S')"
    } >> "$LOG_FILE"
    
    # Check for completion signal
    if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
        echo ""
        echo "🎉 Ralph signaled COMPLETE after $ITERATION iterations"
        echo "📂 Logs saved to: ralph-logs/${PRD_NAME}_${TIMESTAMP}_*.log"
        exit 0
    fi
    
    # Brief pause between iterations
    sleep 2
done

echo ""
echo "⚠️  Hit max iterations ($MAX_ITERATIONS) without COMPLETE signal"
echo "Check progress.txt and $PRD_FILE to see what's left"
echo "📂 Logs saved to: ralph-logs/${PRD_NAME}_${TIMESTAMP}_*.log"
EOF
chmod +x ~/ralph-docker/ralph-loop.sh
```

**ralph-reset.sh** — Deletes a container so you can start fresh. Project files are safe (they're on your Mac or in a Docker volume). This does NOT delete volumes.

```bash
cat > ~/ralph-docker/ralph-reset.sh << 'EOF'
#!/bin/bash
# ralph-reset.sh - Remove a Ralph container to start fresh
# Usage: ralph-reset.sh <container-name>
# 
# SAFE: This only removes the container, NOT your project files:
#   - ralph-start.sh projects: Files are on your Mac (mounted)
#   - ralph-clone.sh projects: Files are in Docker volume (preserved)
#
# To also delete the volume (rare): docker volume rm ralph-vol-<repo-name>

if [ -z "$1" ]; then
    echo "Usage: ralph-reset.sh <container-name>"
    echo ""
    echo "Your containers:"
    docker ps -a --format '{{.Names}}' | grep "^ralph-" || echo "  (none found)"
    exit 1
fi

CONTAINER_NAME="$1"

# Check if container exists
if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "❌ Container '$CONTAINER_NAME' not found"
    echo ""
    echo "Your containers:"
    docker ps -a --format '{{.Names}}' | grep "^ralph-" || echo "  (none found)"
    exit 1
fi

echo "⚠️  This will delete container: $CONTAINER_NAME"
echo "   Project files are SAFE (on Mac or in Docker volume)"
read -p "Continue? (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker rm -f "$CONTAINER_NAME"
    echo "✅ Container removed"
    echo "   Run ralph-start.sh or ralph-clone.sh to recreate"
else
    echo "Cancelled"
fi
EOF
chmod +x ~/ralph-docker/ralph-reset.sh
```

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

### Step 3.1: Navigate to Your Project

```bash
cd /path/to/your/project
```

Or if using the clone workflow, you'll run `ralph-clone.sh` later instead.

### Step 3.2: Create the Git Safety Hook

This blocks dangerous git commands inside the container as a safety net (branch protection is the real safeguard, this is defense in depth).

Create `.git-hooks/pre-push`:
```bash
mkdir -p .git-hooks
cat > .git-hooks/pre-push << 'EOF'
#!/bin/bash
# Block pushes to main/master from Claude

protected_branches=("main" "master")
current_branch=$(git symbolic-ref HEAD 2>/dev/null | sed 's|refs/heads/||')

for branch in "${protected_branches[@]}"; do
    if [ "$current_branch" = "$branch" ]; then
        echo "❌ BLOCKED: Cannot push directly to $branch"
        echo "Create a feature branch and PR instead."
        exit 1
    fi
done

exit 0
EOF
chmod +x .git-hooks/pre-push
```

Configure git to use this hooks directory:
```bash
git config core.hooksPath .git-hooks
```

Commit the hook:
```bash
git add .git-hooks
git commit -m "Add git safety hook to block direct pushes to main"
```

### Step 3.3: Create Minimal CLAUDE.md Base

Start with a minimal template. Claude will expand this by exploring your project.

```bash
cat > CLAUDE.md << 'EOF'
# Project Context

## Commands
- `npm install` - Install dependencies
- `npm run dev` - Start dev server  
- `npm test` - Run tests
- `npm run build` - Production build

## Git Rules
- NEVER push to main directly
- Always work on feature branches
- Make small, logical commits with clear messages

## Testing Rules
- ALL changes MUST have tests
- Tests MUST pass before committing

## Project Details
[To be filled by project discovery - see Step 3.4]
EOF
```

### Step 3.4: Run Project Discovery

Have Claude explore your project and complete CLAUDE.md with actual details.

```bash
cd /path/to/your/project
claude
```

Give Claude this prompt:

```
Explore this project and update CLAUDE.md with:

1. **Tech Stack**: What frameworks, libraries, and tools are used? (Check package.json, config files)

2. **Project Structure**: Describe the folder organization and what goes where.

3. **Coding Patterns**: Identify INTENTIONAL patterns and conventions:
   - Component structure patterns
   - State management approach
   - Styling approach (CSS modules, Tailwind, styled-components, etc.)
   - API/data fetching patterns
   - Error handling patterns
   
   IMPORTANT: Only document patterns that appear intentional and consistent.
   Ignore inconsistencies or anti-patterns—these are technical debt, not standards.

4. **Testing Setup**: 
   - What test framework is used?
   - Where do tests live?
   - Any testing utilities or patterns in use?
   - How to run specific tests vs all tests?

5. **Dev Server**: What port? Any environment setup needed?

AVOID REDUNDANCY:
- Do NOT duplicate information already in README.md or other docs
- Do NOT document things that are obvious or easily discoverable
- ONLY include: critical info, non-obvious patterns, context that saves 
  searching the whole project
- Keep it concise—this file should reduce cognitive load, not add to it

Do NOT invent patterns that don't exist. Only document what you observe.
Save the updated CLAUDE.md when done.
```

Review the output and adjust anything that seems wrong.

### Step 3.5: Create RALPH_PROMPT.md

This is what Claude reads each iteration. The PRD filename is passed when invoking the script.

```bash
cat > RALPH_PROMPT.md << 'EOF'
# Ralph Instructions

Read these files first:
1. CLAUDE.md - Project context and rules
2. The PRD file (you were told which one)
3. progress.txt - What's been done

## Your Job (ONE TASK PER ITERATION)

You will complete exactly ONE task per iteration. Not zero, not two. One.

1. If not already on a feature branch, create one based on the PRD filename:
   `git checkout -b ralph/[prd-number]-[brief-description]`
   Example: `git checkout -b ralph/001-test-infrastructure`
2. Read the PRD file and find all tasks where `testsPassing: false`
3. Choose the BEST NEXT TASK to work on (not necessarily the first one—pick the most logical next step based on dependencies, complexity, and what's already done)
4. Implement ONLY that task with appropriate tests
5. Run the test command from CLAUDE.md - fix until ALL tests pass
6. Commit with a clear message describing what you did
7. Update the PRD file: set `testsPassing: true` for ONLY the completed task
8. APPEND summary to progress.txt (add to end of file, do not modify existing content)
9. STOP this iteration (the loop will start a new one)

## Rules

- **One task per iteration.** Do not continue to the next task.
- **No drive-by refactoring.** Only touch code directly related to your current task. If you see something else that needs fixing, add it as a new task to the PRD instead of fixing it now.
- **Never push to main.** Only push your feature branch.
- **Never commit failing tests.**
- **Small commits.** One logical change per commit.
- **If stuck on same task 3+ times**, mark it with a `blocked` field explaining why, then pick a different task.

## Modifying the PRD

You may modify the PRD file in these specific ways:

**Adding tasks:** If you discover something that needs to be done that isn't in the PRD, add it as a new task with a new ID and `testsPassing: false`. APPEND a note to progress.txt.

**Splitting tasks:** If a task is too large to complete in one iteration, split it into smaller subtasks:
- Keep the original task ID as a prefix (e.g., "003" becomes "003a", "003b", "003c")
- Mark the original as split by adding `"split": true`
- Create the subtasks with `testsPassing: false`
- APPEND a note to progress.txt

Do NOT delete tasks. Do NOT rename task IDs (except for splitting). Do NOT modify completed tasks.

## After Each Task

APPEND to progress.txt (add to end of file):
```
---
[TIMESTAMP]
Task: [task id]
Status: done|blocked|split

What I did:
- [Detailed list of changes made]
- [Include specific files modified]
- [Include any key decisions or approaches taken]

Commit: [hash]
Notes: [any PRD modifications, blockers encountered, or issues to flag]
```

## When All Tasks Complete

When there are no more tasks with `testsPassing: false` in the PRD file:

1. `git push -u origin [branch-name]`
2. Output exactly this completion signal (the loop script detects this):

<promise>COMPLETE</promise>

3. Then output: "✅ All tasks complete. Branch [branch-name] pushed. Please review PR on GitHub."
EOF
```

### Step 3.5: Create PRD Directory and Template

PRDs are numbered for history (e.g., `001_initial_setup.json`, `002_user_auth.json`). **Task IDs are for reference only—they do NOT imply execution order.** Ralph picks the best next task dynamically.

```bash
# Create PRD directory
mkdir -p prds

# Create the template
cat > prds/PRD_TEMPLATE.json << 'EOF'
{
  "sprint": "[Name]",
  "created": "[YYYY-MM-DD]",
  "overview": "[Brief description of what this sprint accomplishes]",
  "note": "Task IDs are for reference only. Order is determined dynamically.",
  "tasks": [
    {
      "id": "001",
      "name": "[Task Name]",
      "description": "[What needs to be done]",
      "acceptanceCriteria": [
        "Criterion 1",
        "Criterion 2"
      ],
      "testsPassing": false
    }
  ]
}
EOF

# Create a helper script to start a new PRD
cat > prds/new-prd.sh << 'EOF'
#!/bin/bash
# Usage: ./new-prd.sh "sprint name"

NAME="${1:-unnamed}"
# Find the next number
LAST=$(ls -1 prds/*.json 2>/dev/null | grep -v TEMPLATE | sort -r | head -1 | grep -oE '[0-9]{3}' | head -1)
NEXT=$(printf "%03d" $((10#${LAST:-0} + 1)))
FILENAME="prds/${NEXT}_$(echo "$NAME" | tr ' ' '_' | tr '[:upper:]' '[:lower:]').json"

cp prds/PRD_TEMPLATE.json "$FILENAME"
sed -i '' "s/\[Name\]/$NAME/" "$FILENAME" 2>/dev/null || sed -i "s/\[Name\]/$NAME/" "$FILENAME"
sed -i '' "s/\[YYYY-MM-DD\]/$(date +%Y-%m-%d)/" "$FILENAME" 2>/dev/null || sed -i "s/\[YYYY-MM-DD\]/$(date +%Y-%m-%d)/" "$FILENAME"

echo "Created: $FILENAME"
echo "Run Ralph with: ./ralph-loop.sh $FILENAME"
EOF
chmod +x prds/new-prd.sh
```

**Workflow:**
1. `./prds/new-prd.sh "user authentication"` → creates `prds/001_user_authentication.json`
2. Edit the PRD file with your tasks
3. Run Ralph: `./ralph-loop.sh prds/001_user_authentication.json`
4. When done, the numbered file serves as history

### Step 3.6: Create progress.txt

```bash
cat > progress.txt << 'EOF'
# Ralph Progress Log

---
[Setup]
Project configured for Ralph workflow.
EOF
```

### Step 3.7: Copy UI_TESTING.md (Reference for UI Projects)

This file contains UI testing standards. Claude reads it when working on UI tasks.

```bash
cp ~/ralph/templates/UI_TESTING.md .
```

The file defines accessibility-first testing standards: semantic HTML, ARIA attributes for interactive elements, and using Playwright's accessibility snapshots to verify UI correctness.

### Step 3.8: Create PRD_REFINE.md (PRD Quality Check)

This prompt helps refine PRDs to ensure tasks are right-sized.

```bash
cat > prds/PRD_REFINE.md << 'EOF'
# PRD Refinement

Review the PRD for task sizing and acceptance criteria quality.

## Right-Sized Task
- Completable in one focused session
- Has clear "done" state (testable)
- Dependencies are explicit

## Too Big (split it)
- Has multiple distinct deliverables
- Naturally breaks into "first X, then Y"

## Too Small (merge it)
- Just a sub-step of another task
- Can't be tested independently

## Task Order

Task IDs are for REFERENCE ONLY—not execution order.
Ralph picks the best next task dynamically based on:
- What's already done
- What makes logical sense
- Dependencies between tasks

If tasks have hard dependencies, note them in the description:
- "Requires: 003" or "After auth is complete"
- Do NOT assume numeric order = execution order

## Acceptance Criteria Quality

Good criteria test PURPOSE, not implementation:
- "User can log in with email/password" (purpose)
- "Login form calls /api/auth endpoint" (implementation - too rigid)

Avoid:
- Specifying exact function names or file structures
- Requiring specific libraries or patterns
- Testing internal state rather than observable behavior

## Output Format

For each task:
- KEEP: [task id] - [reason]
- SPLIT: [task id] into [subtasks]
- MERGE: [task ids] into [single task]
- FIX: [task id] - [criteria issue]

Or if all tasks are ready: "PRD is ready"
EOF
```

### Step 3.9: Copy Ralph Scripts to Project Root

Copy from your machine-level `~/ralph-docker/` to your project root:

```bash
cp ~/ralph-docker/ralph-loop.sh ./ralph-loop.sh
cp ~/ralph-docker/ralph-once.sh ./ralph-once.sh
chmod +x ralph-loop.sh ralph-once.sh
```

### Step 3.10: Update .gitignore

```bash
cat >> .gitignore << 'EOF'

# Ralph logs (iteration transcripts for debugging)
ralph-logs/
EOF
```

### Step 3.11: Create .claudeignore

Prevent Claude from reading sensitive or wasteful files. Claude Code doesn't do RAG on large files—it reads them into context, which wastes tokens and can hit limits.

```bash
cat > .claudeignore << 'EOF'
# === SECRETS (never let Claude read these) ===
.env
.env.*
*.pem
*.key
secrets/

# === LARGE GENERATED FILES (waste of context) ===
# Lock files - huge, not useful
package-lock.json
yarn.lock
pnpm-lock.yaml

# Build outputs
/build/
/dist/
/.next/
/.nuxt/
/.output/
/.react-router/

# Dependencies
/node_modules/

# Generated code (Claude can read the source schemas instead)
# Uncomment if applicable:
# /app/generated/        # Prisma
# /src/gql/              # GraphQL codegen
# /__generated__/        # Relay

# === TEST ARTIFACTS (usually not helpful) ===
/playwright-report/
/test-results/
/coverage/
/.nyc_output/

# === RALPH LOGS ===
# These COULD help Claude debug issues from previous iterations,
# but they're large and not always present (gitignored).
# Uncomment to exclude:
# /ralph-logs/

# === OS FILES ===
.DS_Store
Thumbs.db
EOF
```

**Customize for your project:** Review what's in your `.gitignore`—most of those should also be in `.claudeignore`. The key categories:
- **Secrets** — Always ignore
- **Generated/compiled** — Ignore (Claude can read source files)
- **Dependencies** — Always ignore (`node_modules` is massive)
- **Test artifacts** — Usually ignore (reports, screenshots)
- **Ralph logs** — Optional (might help debugging, but large)

### Step 3.12: Commit Setup

```bash
git add CLAUDE.md RALPH_PROMPT.md UI_TESTING.md prds/ progress.txt ralph-loop.sh ralph-once.sh .git-hooks .gitignore .claudeignore
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
