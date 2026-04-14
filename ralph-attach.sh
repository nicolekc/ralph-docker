#!/bin/bash
# ralph-attach.sh - Open a new shell inside a running Ralph container.
# Usage: ralph-attach.sh <container-name>
#
# This does NOT start a new Ralph session — it just gives you another TTY
# on an existing one (e.g. to tail logs while a loop is running).
# Use `docker ps --filter name=ralph-` to list live sessions.

NAME="${1:-}"
if [ -z "$NAME" ]; then
    echo "Usage: ralph-attach.sh <container-name>"
    echo ""
    echo "Running Ralph containers:"
    docker ps --filter "name=ralph-" --format '  {{.Names}}' 2>/dev/null || true
    exit 1
fi

exec docker exec -it "$NAME" bash
