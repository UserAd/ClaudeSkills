#!/bin/bash
# exit_subagent.sh - Gracefully exit a Claude subagent and close the window
#
# Usage: exit_subagent.sh <window-name>
#
# Arguments:
#   window-name  Name of the tmux window containing the subagent
#
# Output: "Done" on success, error message on failure
#
# Behavior:
#   1. Send /exit command to the subagent
#   2. Wait 1 second for graceful shutdown
#   3. Kill the window if still present
#
# Example:
#   exit_subagent.sh agent-task-1

set -e

WINDOW_NAME="$1"

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

TARGET="$SESSION:$WINDOW_NAME"

# Check if window exists
if ! $TMUX_BIN list-windows -t "$SESSION" -F "#{window_name}" | grep -q "^${WINDOW_NAME}$"; then
    echo "Error: window '$WINDOW_NAME' does not exist"
    exit 1
fi

# Send /exit command
$TMUX_BIN send-keys -t "$TARGET" -l "/exit"
sleep 1
$TMUX_BIN send-keys -t "$TARGET" Enter

# Wait for graceful shutdown
sleep 1

# Kill window if still present
if $TMUX_BIN list-windows -t "$SESSION" -F "#{window_name}" | grep -q "^${WINDOW_NAME}$"; then
    $TMUX_BIN kill-window -t "$TARGET"
fi

echo "Done"
