#!/bin/bash
# orca-loop.sh - Run Ralph in a loop until done
# Usage: ./orca-loop.sh <prd-file> [max-iterations] [prompt-file]
# Run this INSIDE the container, in /workspace

PRD_FILE="${1:-}"
MAX_ITERATIONS="${2:-20}"
PROMPT_FILE="${3:-ORCA_PROMPT.md}"

# PRD file is required
if [ -z "$PRD_FILE" ]; then
    echo "❌ Error: PRD file required"
    echo "Usage: ./orca-loop.sh <prd-file> [max-iterations] [prompt-file]"
    echo "Example: ./orca-loop.sh prds/001_test_infrastructure.json 20"
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

echo "🔄 Ralph Loop Starting"
echo "📋 Prompt: $PROMPT_FILE"
echo "📝 PRD: $PRD_FILE"
echo "🔢 Max iterations: $MAX_ITERATIONS"
echo ""
echo "⏹️  Ctrl+C to stop, or wait for COMPLETE signal"
echo ""

ITERATION=0
while [ $ITERATION -lt $MAX_ITERATIONS ]; do
    ITERATION=$((ITERATION + 1))

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔁 Iteration $ITERATION of $MAX_ITERATIONS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Run claude in print mode (buffered output)
    OUTPUT=$(claude -p "Read $PROMPT_FILE for instructions. The PRD file is: $PRD_FILE" --dangerously-skip-permissions 2>&1)

    # Display output
    echo "$OUTPUT"

    # Check for completion signal
    if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
        echo ""
        echo "🎉 Ralph signaled COMPLETE after $ITERATION iterations"
        exit 0
    fi

    # Brief pause between iterations
    sleep 2
done

echo ""
echo "⚠️  Hit max iterations ($MAX_ITERATIONS) without COMPLETE signal"
echo "Check $PRD_FILE to see what's left"
