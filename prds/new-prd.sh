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
