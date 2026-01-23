#!/bin/bash
#
# Ralph Project Setup Script
#
# Copies all necessary Ralph files to a target project.
# Safe to run multiple times (idempotent).
#
# Usage:
#   ./install.sh /path/to/your/project
#
# What it does:
#   - Copies templates (CLAUDE.md.template, progress.txt.template, .claudeignore)
#   - Sets up .git-hooks/pre-push and configures git to use it
#   - Copies RALPH_PROMPT.md
#   - Copies ralph-loop.sh and ralph-once.sh
#   - Copies prds/ directory (template and refine docs)
#   - Copies .claude/skills/ directory
#   - Copies UI_TESTING.md
#   - Updates .gitignore to exclude ralph-logs/
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where this script lives (Ralph repo root)
RALPH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for target project argument
if [ -z "$1" ]; then
    echo -e "${RED}Error: Please provide the path to your project.${NC}"
    echo ""
    echo "Usage: $0 /path/to/your/project"
    echo ""
    echo "Example:"
    echo "  $0 ~/projects/my-app"
    exit 1
fi

TARGET_DIR="$1"

# Verify target exists and is a directory
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${RED}Error: '$TARGET_DIR' is not a directory or does not exist.${NC}"
    exit 1
fi

# Verify target is a git repository
if [ ! -d "$TARGET_DIR/.git" ]; then
    echo -e "${RED}Error: '$TARGET_DIR' is not a git repository.${NC}"
    echo "Please initialize git first: cd $TARGET_DIR && git init"
    exit 1
fi

echo "Installing Ralph to: $TARGET_DIR"
echo ""

# Track what we do
COPIED=()
SKIPPED=()
CREATED=()

# Helper function to copy file if it doesn't exist or is different
copy_file() {
    local src="$1"
    local dest="$2"
    local dest_name="${3:-$(basename "$dest")}"

    if [ ! -f "$src" ]; then
        echo -e "${RED}Warning: Source file not found: $src${NC}"
        return 1
    fi

    if [ -f "$dest" ]; then
        # File exists, check if identical
        if cmp -s "$src" "$dest"; then
            SKIPPED+=("$dest_name (unchanged)")
            return 0
        else
            # Files differ - overwrite with backup
            cp "$dest" "${dest}.bak"
            cp "$src" "$dest"
            COPIED+=("$dest_name (updated, backup saved)")
            return 0
        fi
    else
        # File doesn't exist, copy it
        cp "$src" "$dest"
        COPIED+=("$dest_name")
        return 0
    fi
}

# Helper function to copy directory recursively
copy_dir() {
    local src="$1"
    local dest="$2"
    local name="$3"

    if [ ! -d "$src" ]; then
        echo -e "${RED}Warning: Source directory not found: $src${NC}"
        return 1
    fi

    mkdir -p "$dest"
    cp -r "$src"/* "$dest"/ 2>/dev/null || true
    COPIED+=("$name/")
}

# 1. Copy CLAUDE.md.template -> CLAUDE.md (only if CLAUDE.md doesn't exist)
if [ ! -f "$TARGET_DIR/CLAUDE.md" ]; then
    cp "$RALPH_DIR/templates/CLAUDE.md.template" "$TARGET_DIR/CLAUDE.md"
    CREATED+=("CLAUDE.md (from template - run /discover to populate)")
else
    SKIPPED+=("CLAUDE.md (already exists)")
fi

# 2. Copy progress.txt.template -> progress.txt (only if progress.txt doesn't exist)
if [ ! -f "$TARGET_DIR/progress.txt" ]; then
    cp "$RALPH_DIR/templates/progress.txt.template" "$TARGET_DIR/progress.txt"
    CREATED+=("progress.txt (from template)")
else
    SKIPPED+=("progress.txt (already exists)")
fi

# 3. Copy .claudeignore
copy_file "$RALPH_DIR/templates/.claudeignore" "$TARGET_DIR/.claudeignore" ".claudeignore"

# 4. Set up .git-hooks/pre-push
mkdir -p "$TARGET_DIR/.git-hooks"
copy_file "$RALPH_DIR/templates/.git-hooks/pre-push" "$TARGET_DIR/.git-hooks/pre-push" ".git-hooks/pre-push"
chmod +x "$TARGET_DIR/.git-hooks/pre-push"

# Configure git to use the hooks directory
CURRENT_HOOKS_PATH=$(cd "$TARGET_DIR" && git config --get core.hooksPath 2>/dev/null || echo "")
if [ "$CURRENT_HOOKS_PATH" != ".git-hooks" ]; then
    (cd "$TARGET_DIR" && git config core.hooksPath .git-hooks)
    COPIED+=("git config core.hooksPath .git-hooks")
else
    SKIPPED+=("git hooks path (already configured)")
fi

# 5. Copy RALPH_PROMPT.md
copy_file "$RALPH_DIR/RALPH_PROMPT.md" "$TARGET_DIR/RALPH_PROMPT.md" "RALPH_PROMPT.md"

# 6. Copy ralph-loop.sh and ralph-once.sh
copy_file "$RALPH_DIR/ralph-loop.sh" "$TARGET_DIR/ralph-loop.sh" "ralph-loop.sh"
copy_file "$RALPH_DIR/ralph-once.sh" "$TARGET_DIR/ralph-once.sh" "ralph-once.sh"
chmod +x "$TARGET_DIR/ralph-loop.sh" "$TARGET_DIR/ralph-once.sh"

# 7. Copy UI_TESTING.md
copy_file "$RALPH_DIR/templates/UI_TESTING.md" "$TARGET_DIR/UI_TESTING.md" "UI_TESTING.md"

# 8. Set up prds/ directory
mkdir -p "$TARGET_DIR/prds"
copy_file "$RALPH_DIR/prds/PRD_TEMPLATE.json" "$TARGET_DIR/prds/PRD_TEMPLATE.json" "prds/PRD_TEMPLATE.json"
copy_file "$RALPH_DIR/prds/PRD_REFINE.md" "$TARGET_DIR/prds/PRD_REFINE.md" "prds/PRD_REFINE.md"

# 9. Copy .claude/skills/ directory
mkdir -p "$TARGET_DIR/.claude/skills"
if [ -d "$RALPH_DIR/.claude/skills/discover" ]; then
    mkdir -p "$TARGET_DIR/.claude/skills/discover"
    copy_file "$RALPH_DIR/.claude/skills/discover/SKILL.md" "$TARGET_DIR/.claude/skills/discover/SKILL.md" ".claude/skills/discover/SKILL.md"
fi
if [ -d "$RALPH_DIR/.claude/skills/refine" ]; then
    mkdir -p "$TARGET_DIR/.claude/skills/refine"
    copy_file "$RALPH_DIR/.claude/skills/refine/SKILL.md" "$TARGET_DIR/.claude/skills/refine/SKILL.md" ".claude/skills/refine/SKILL.md"
fi

# 10. Update .gitignore for ralph-logs/
if [ -f "$TARGET_DIR/.gitignore" ]; then
    if ! grep -q "ralph-logs/" "$TARGET_DIR/.gitignore"; then
        echo "" >> "$TARGET_DIR/.gitignore"
        echo "# Ralph logs (iteration transcripts for debugging)" >> "$TARGET_DIR/.gitignore"
        echo "ralph-logs/" >> "$TARGET_DIR/.gitignore"
        COPIED+=(".gitignore (added ralph-logs/)")
    else
        SKIPPED+=(".gitignore (ralph-logs/ already present)")
    fi
else
    # Create .gitignore with ralph-logs/
    echo "# Ralph logs (iteration transcripts for debugging)" > "$TARGET_DIR/.gitignore"
    echo "ralph-logs/" >> "$TARGET_DIR/.gitignore"
    CREATED+=(".gitignore")
fi

# Print summary
echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""

if [ ${#CREATED[@]} -gt 0 ]; then
    echo "Created:"
    for item in "${CREATED[@]}"; do
        echo "  + $item"
    done
    echo ""
fi

if [ ${#COPIED[@]} -gt 0 ]; then
    echo "Copied/Updated:"
    for item in "${COPIED[@]}"; do
        echo "  → $item"
    done
    echo ""
fi

if [ ${#SKIPPED[@]} -gt 0 ]; then
    echo "Skipped (already up to date):"
    for item in "${SKIPPED[@]}"; do
        echo "  - $item"
    done
    echo ""
fi

echo -e "${YELLOW}Next steps:${NC}"
echo "  1. cd $TARGET_DIR"
echo "  2. Run 'claude' and then '/discover' to explore your project and populate CLAUDE.md"
echo "  3. Commit the setup: git add -A && git commit -m 'Add Ralph workflow configuration'"
echo ""
