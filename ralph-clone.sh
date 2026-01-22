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
        -v "$HOME/.gitconfig:/home/node/.gitconfig:ro" \
        -v "$HOME/.config/claude:/home/node/.config/claude" \
        -v "$HOME/.ssh:/home/node/.ssh:ro" \
        -e "GIT_AUTHOR_NAME=claude-bot" \
        -e "GIT_AUTHOR_EMAIL=claude-bot@users.noreply.github.com" \
        -e "GIT_COMMITTER_NAME=claude-bot" \
        -e "GIT_COMMITTER_EMAIL=claude-bot@users.noreply.github.com" \
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
fi