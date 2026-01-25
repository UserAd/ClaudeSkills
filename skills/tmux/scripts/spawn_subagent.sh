#!/bin/bash
# spawn_subagent.sh - Spawn a Claude subagent or command in a new tmux window
#
# Usage: spawn_subagent.sh <window-name> [command]
#
# Arguments:
#   window-name  Unique name for the tmux window (e.g., agent-research-1)
#   command      Optional command to run (default: claude --dangerously-skip-permissions)
#
# Output: "Done" on success, error message on failure
#
# Example:
#   spawn_subagent.sh agent-task-1
#   spawn_subagent.sh agent-task-1 "claude --agent researcher --dangerously-skip-permissions"

set -e

WINDOW_NAME="$1"
COMMAND="${2:-claude --dangerously-skip-permissions}"

if [ -z "$WINDOW_NAME" ]; then
    echo "Error: window-name is required"
    exit 1
fi

# Get tmux binary path
TMUX_BIN=$(which tmux)
if [ -z "$TMUX_BIN" ]; then
    echo "Error: tmux not found"
    exit 1
fi

# Get current session
SESSION=$($TMUX_BIN display-message -p '#S')
if [ -z "$SESSION" ]; then
    echo "Error: not in a tmux session"
    exit 1
fi

# Check if window already exists
if $TMUX_BIN list-windows -t "$SESSION" -F "#{window_name}" | grep -q "^${WINDOW_NAME}$"; then
    echo "Error: window '$WINDOW_NAME' already exists"
    exit 1
fi

# Create new window with command
$TMUX_BIN new-window -d -t "$SESSION" -n "$WINDOW_NAME" "$COMMAND"

echo "Done"
