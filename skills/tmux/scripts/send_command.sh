#!/bin/bash
# send_command.sh - Send a command to a tmux window and execute it
#
# Usage: send_command.sh <window-name> <command>
#
# Arguments:
#   window-name  Name of the target tmux window
#   command      Command text to send to the window
#
# Output: "Done" on success, error message on failure
#
# Behavior:
#   1. Send the command text to the window
#   2. Wait 1 second
#   3. Send Enter to execute
#
# Example:
#   send_command.sh agent-task-1 "Research X and write to /tmp/output.md"

set -e

WINDOW_NAME="$1"
COMMAND="$2"

if [ -z "$WINDOW_NAME" ]; then
    echo "Error: window-name is required"
    exit 1
fi

if [ -z "$COMMAND" ]; then
    echo "Error: command is required"
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

# Verify window exists
if ! $TMUX_BIN list-windows -t "$SESSION" -F "#{window_name}" | grep -q "^${WINDOW_NAME}$"; then
    echo "Error: window '$WINDOW_NAME' does not exist"
    exit 1
fi

TARGET="$SESSION:$WINDOW_NAME"

# Send command text
$TMUX_BIN send-keys -t "$TARGET" -l "$COMMAND"

# Wait 1 second
sleep 1

# Send Enter to execute
$TMUX_BIN send-keys -t "$TARGET" Enter

echo "Done"
