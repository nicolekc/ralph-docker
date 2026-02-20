#!/bin/bash
#
# Ralph Framework Installer
#
# Installs the Ralph agent framework into a target project.
# Safe to run multiple times (idempotent).
#
# Usage:
#   ./install.sh /path/to/project
#   ./install.sh --bash-loop /path/to/project
#

set -e

RALPH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Argument parsing ---

BASH_LOOP=false
TARGET_DIR=""

for arg in "$@"; do
    case "$arg" in
        --bash-loop)
            BASH_LOOP=true
            ;;
        -*)
            echo "Error: Unknown option '$arg'"
            echo ""
            echo "Usage: $0 [--bash-loop] /path/to/project"
            exit 1
            ;;
        *)
            if [ -n "$TARGET_DIR" ]; then
                echo "Error: Multiple target directories specified."
                echo ""
                echo "Usage: $0 [--bash-loop] /path/to/project"
                exit 1
            fi
            TARGET_DIR="$arg"
            ;;
    esac
done

if [ -z "$TARGET_DIR" ]; then
    echo "Error: Please provide the path to your project."
    echo ""
    echo "Usage: $0 [--bash-loop] /path/to/project"
    echo ""
    echo "Examples:"
    echo "  $0 ~/projects/my-app"
    echo "  $0 --bash-loop ~/projects/my-app"
    exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: '$TARGET_DIR' is not a directory or does not exist."
    exit 1
fi

if [ ! -d "$TARGET_DIR/.git" ]; then
    echo "Error: '$TARGET_DIR' is not a git repository."
    echo "Initialize git first: cd $TARGET_DIR && git init"
    exit 1
fi

# Resolve to absolute path
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

# --- Tracking ---

CREATED=()
UPDATED=()
UNCHANGED=()

# --- Helpers ---

# Copy a single file. Framework-managed files overwrite; user files skip.
#   copy_framework_file SRC DEST LABEL
#     Always overwrites if content differs.
#   copy_user_file SRC DEST LABEL
#     Only creates if absent. Never overwrites.
copy_framework_file() {
    local src="$1" dest="$2" label="$3"
    if [ ! -f "$src" ]; then
        echo "Warning: Source not found: $src"
        return 1
    fi
    if [ -f "$dest" ]; then
        if cmp -s "$src" "$dest"; then
            UNCHANGED+=("$label")
        else
            cp "$src" "$dest"
            UPDATED+=("$label")
        fi
    else
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
        CREATED+=("$label")
    fi
}

copy_user_file() {
    local src="$1" dest="$2" label="$3"
    if [ -f "$dest" ]; then
        UNCHANGED+=("$label")
    else
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
        CREATED+=("$label")
    fi
}

# Copy a directory tree. Framework-managed: overwrites all files.
#   copy_framework_dir SRC DEST LABEL
copy_framework_dir() {
    local src="$1" dest="$2" label="$3"
    if [ ! -d "$src" ]; then
        echo "Warning: Source directory not found: $src"
        return 1
    fi

    local had_changes=false
    local was_new=false

    if [ ! -d "$dest" ]; then
        was_new=true
    fi

    # Walk source and copy each file
    while IFS= read -r -d '' file; do
        local rel="${file#$src/}"
        local dest_file="$dest/$rel"
        mkdir -p "$(dirname "$dest_file")"
        if [ -f "$dest_file" ]; then
            if ! cmp -s "$file" "$dest_file"; then
                cp "$file" "$dest_file"
                had_changes=true
            fi
        else
            cp "$file" "$dest_file"
            had_changes=true
        fi
    done < <(find "$src" -type f -print0)

    if $was_new; then
        CREATED+=("$label")
    elif $had_changes; then
        UPDATED+=("$label")
    else
        UNCHANGED+=("$label")
    fi
}

echo "Installing Ralph framework to $TARGET_DIR..."
echo ""

# --- 1. Framework core: framework/ -> .ralph/ ---

copy_framework_dir "$RALPH_DIR/framework" "$TARGET_DIR/.ralph" ".ralph/ (framework core)"

# --- 2. Skills ---

copy_framework_file \
    "$RALPH_DIR/.claude/skills/ralph/SKILL.md" \
    "$TARGET_DIR/.claude/skills/ralph/SKILL.md" \
    ".claude/skills/ralph/ (PRD execution)"

copy_framework_file \
    "$RALPH_DIR/.claude/skills/discover/SKILL.md" \
    "$TARGET_DIR/.claude/skills/discover/SKILL.md" \
    ".claude/skills/discover/ (project discovery)"

copy_framework_file \
    "$RALPH_DIR/.claude/skills/refine/SKILL.md" \
    "$TARGET_DIR/.claude/skills/refine/SKILL.md" \
    ".claude/skills/refine/ (PRD refinement)"

# --- 3. ralph-context/ scaffold ---

if [ ! -d "$TARGET_DIR/ralph-context" ]; then
    for subdir in overrides knowledge prds designs tasks; do
        mkdir -p "$TARGET_DIR/ralph-context/$subdir"
        touch "$TARGET_DIR/ralph-context/$subdir/.gitkeep"
    done
    CREATED+=("ralph-context/ (project context)")
else
    UNCHANGED+=("ralph-context/")
fi

# --- 4. CLAUDE.md (user file -- create only) ---

copy_user_file \
    "$RALPH_DIR/templates/CLAUDE.md.template" \
    "$TARGET_DIR/CLAUDE.md" \
    "CLAUDE.md (run /discover to populate)"

# --- 5. .claudeignore (framework-managed) ---

copy_framework_file \
    "$RALPH_DIR/templates/.claudeignore" \
    "$TARGET_DIR/.claudeignore" \
    ".claudeignore"

# --- 6. Git hooks ---

mkdir -p "$TARGET_DIR/.git-hooks"
copy_framework_file \
    "$RALPH_DIR/templates/.git-hooks/pre-push" \
    "$TARGET_DIR/.git-hooks/pre-push" \
    ".git-hooks/pre-push"
chmod +x "$TARGET_DIR/.git-hooks/pre-push"

CURRENT_HOOKS_PATH=$(cd "$TARGET_DIR" && git config --get core.hooksPath 2>/dev/null || echo "")
if [ "$CURRENT_HOOKS_PATH" != ".git-hooks" ]; then
    (cd "$TARGET_DIR" && git config core.hooksPath .git-hooks)
fi

# --- 7. .gitignore additions ---

GITIGNORE_ENTRIES=(
    ".ralph-tasks/*/debug-*"
    ".ralph-tasks/*/scratch-*"
    "ralph-logs/"
)

gitignore_changed=false
if [ ! -f "$TARGET_DIR/.gitignore" ]; then
    {
        echo "# Ralph framework"
        for entry in "${GITIGNORE_ENTRIES[@]}"; do
            echo "$entry"
        done
    } > "$TARGET_DIR/.gitignore"
    CREATED+=(".gitignore")
    gitignore_changed=true
else
    missing_entries=()
    for entry in "${GITIGNORE_ENTRIES[@]}"; do
        if ! grep -qF "$entry" "$TARGET_DIR/.gitignore"; then
            missing_entries+=("$entry")
        fi
    done
    if [ ${#missing_entries[@]} -gt 0 ]; then
        {
            echo ""
            echo "# Ralph framework"
            for entry in "${missing_entries[@]}"; do
                echo "$entry"
            done
        } >> "$TARGET_DIR/.gitignore"
        UPDATED+=(".gitignore (added ralph entries)")
        gitignore_changed=true
    else
        UNCHANGED+=(".gitignore")
    fi
fi

# --- 8. Bash-loop files (opt-in) ---

if $BASH_LOOP; then
    copy_framework_file \
        "$RALPH_DIR/RALPH_PROMPT.md" \
        "$TARGET_DIR/RALPH_PROMPT.md" \
        "RALPH_PROMPT.md (bash-loop mode)"

    copy_framework_file \
        "$RALPH_DIR/ralph-loop.sh" \
        "$TARGET_DIR/ralph-loop.sh" \
        "ralph-loop.sh (bash-loop mode)"

    copy_framework_file \
        "$RALPH_DIR/ralph-once.sh" \
        "$TARGET_DIR/ralph-once.sh" \
        "ralph-once.sh (bash-loop mode)"

    chmod +x "$TARGET_DIR/ralph-loop.sh" "$TARGET_DIR/ralph-once.sh"
fi

# --- Summary ---

if [ ${#CREATED[@]} -gt 0 ]; then
    echo "Created:"
    for item in "${CREATED[@]}"; do
        echo "  + $item"
    done
    echo ""
fi

if [ ${#UPDATED[@]} -gt 0 ]; then
    echo "Updated:"
    for item in "${UPDATED[@]}"; do
        echo "  ~ $item"
    done
    echo ""
fi

if [ ${#UNCHANGED[@]} -gt 0 ]; then
    echo "Unchanged:"
    for item in "${UNCHANGED[@]}"; do
        echo "  = $item"
    done
    echo ""
fi

echo "Next steps:"
echo "  1. cd $TARGET_DIR"
echo "  2. Run 'claude' and then '/discover' to set up project context"
echo "  3. Commit: git add -A && git commit -m 'Install Ralph framework'"
echo ""
