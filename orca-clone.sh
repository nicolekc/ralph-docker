#!/bin/bash
# orca-clone.sh - Start Orca with repo cloned into Docker volume
# Usage: orca-clone.sh <github-repo-url> [--session <name>]
#
# --session <name>   Run a parallel session against the same repo.
#                    Each session gets its own container and Docker volume
#                    (its own clone), so two sessions can work on different
#                    PRDs without git collisions.

set -e  # Exit on any error

REPO_URL=""
SESSION=""

while [ $# -gt 0 ]; do
    case "$1" in
        --session|-s)
            SESSION="$2"
            shift 2
            ;;
        --session=*)
            SESSION="${1#*=}"
            shift
            ;;
        -h|--help)
            echo "Usage: orca-clone.sh <github-repo-url> [--session <name>]"
            exit 0
            ;;
        *)
            if [ -z "$REPO_URL" ]; then
                REPO_URL="$1"
            else
                echo "❌ Unexpected argument: $1"
                echo "Usage: orca-clone.sh <github-repo-url> [--session <name>]"
                exit 1
            fi
            shift
            ;;
    esac
done

if [ -z "$REPO_URL" ]; then
    echo "Usage: orca-clone.sh <github-repo-url> [--session <name>]"
    echo "Example: orca-clone.sh https://github.com/user/repo.git"
    echo "Example: orca-clone.sh https://github.com/user/repo.git --session prdb"
    exit 1
fi

# Extract repo name from URL (handles .git suffix)
REPO_NAME=$(basename "$REPO_URL" .git)

if [ -n "$SESSION" ]; then
    CONTAINER_NAME="orca-${REPO_NAME}-${SESSION}"
    VOLUME_NAME="orca-vol-${REPO_NAME}-${SESSION}"
else
    CONTAINER_NAME="orca-${REPO_NAME}"
    VOLUME_NAME="orca-vol-${REPO_NAME}"
fi

echo "🚀 Orca Container: $CONTAINER_NAME"
echo "📦 Volume: $VOLUME_NAME"

# Create Docker volume if it doesn't exist (persists data between container recreations)
if ! docker volume ls -q | grep -q "^${VOLUME_NAME}$"; then
    echo "📦 Creating volume: $VOLUME_NAME"
    docker volume create "$VOLUME_NAME"
fi

# Resume existing container or create new one
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    # If it's already running, attach a new shell via exec rather than
    # hijacking the original TTY with `docker start -ai`.
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "📦 Container already running — opening a new shell (docker exec)..."
        exec docker exec -it "$CONTAINER_NAME" bash
    fi
    echo "📦 Resuming existing container..."
    docker start -ai "$CONTAINER_NAME"
else
    echo "📦 Creating container and cloning repo..."
    docker run -it \
        --name "$CONTAINER_NAME" \
        --memory="8g" \
        --cpus="4" \
        -v "${VOLUME_NAME}:/workspace" \
        -v "$HOME/.gitconfig:/home/node/.gitconfig:ro" \
        -v "$HOME/.config/claude:/home/node/.config/claude" \
        -v "$HOME/.ssh:/home/node/.ssh:ro" \
        -e "GIT_AUTHOR_NAME=claude-bot" \
        -e "GIT_AUTHOR_EMAIL=claude-bot@users.noreply.github.com" \
        -e "GIT_COMMITTER_NAME=claude-bot" \
        -e "GIT_COMMITTER_EMAIL=claude-bot@users.noreply.github.com" \
        -e "REPO_URL=$REPO_URL" \
        orca-claude:latest \
        bash -c '
            if [ ! -d ".git" ]; then
                echo "📥 Cloning repository..."
                git clone "$REPO_URL" .
            else
                echo "📂 Repository already cloned"
            fi
            exec bash
        '
fi
