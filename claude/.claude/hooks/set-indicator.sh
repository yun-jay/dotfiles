#!/bin/bash
# Reads hook input from stdin and sets wt indicator based on the cwd
STATE="$1"

# Read JSON from stdin and extract cwd
INPUT=$(cat)
CWD=$(echo "$INPUT" | grep -o '"cwd":"[^"]*"' | cut -d'"' -f4)

if [ -n "$CWD" ]; then
  WORKTREE=$(basename "$CWD")
  wt indicator set "$WORKTREE" claude "$STATE" 2>/dev/null
fi
