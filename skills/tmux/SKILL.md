---
name: tmux
description: Use tmux for orchestrating agents and running commands. Use when Claude needs to (1) spawn Claude subagents in background windows, (2) run long-running commands, (3) orchestrate parallel agents, (4) capture window output. Triggers on "tmux", "new tmux window", "run claude", "spawn agent", "parallel agents".
---

# TMUX Orchestration

## Setup

Before any tmux operation:
1. Get binary path: `which tmux` → store as `{{TMUX}}`
2. Get session: `{{TMUX}} display-message -p '#S'` → store as `{{SESSION}}`

## Helper Scripts

Primary method for tmux operations. Located in `scripts/` directory.

| Script | Usage | Description |
|--------|-------|-------------|
| `spawn_subagent.sh` | `<window-name> [command]` | Spawn a subagent in a new window. Default: `claude --dangerously-skip-permissions` |
| `send_command.sh` | `<window-name> <command>` | Send text to window, wait 1s, execute with Enter |
| `exit_subagent.sh` | `<window-name>` | Send /exit, wait 1s, kill window if still present |

Run from skill directory: `./scripts/<script-name>.sh`

All scripts output "Done" on success or an error message on failure.

## Subagent Workflow

1. `.claude/skills/tmux/scripts/spawn_subagent.sh agent-task-1 "claude --agent researcher --dangerously-skip-permissions"`
2. `.claude/skills/tmux/scripts/send_command.sh agent-task-1 "Research X and write to /tmp/output.md"`
3. Await notification via agentmail or display-message (do not poll)
4. Read output file
5. `.claude/skills/tmux/scripts/exit_subagent.sh agent-task-1`

When subagent completes: `{{TMUX}} display-message -d 5000 "{{WINDOW}}: {{MESSAGE}}"`

## Mandatory Requirements

- The agent shall use tmux windows exclusively (not panes).
- The agent shall use unique window names following `agent-{task}-{number}` pattern.
- The agent shall await subagent notifications via agentmail or display-message (no polling).
- When spawning a subagent, the agent shall use `spawn_subagent.sh`.
- When sending commands to a window, the agent shall use `send_command.sh`.
- When stopping a subagent, the agent shall use `exit_subagent.sh`.

## Commands Reference

Raw tmux commands for debugging or edge cases. Use Helper Scripts for standard operations.

| Action | Command |
|--------|---------|
| List windows | `{{TMUX}} list-windows -t "{{SESSION}}" -F "#{window_name}"` |
| New window | `{{TMUX}} new-window -d -t "{{SESSION}}" -n "{{NAME}}" "{{COMMAND}}"` |
| Send text | `{{TMUX}} send-keys -t "{{SESSION}}:{{NAME}}" -l "{{TEXT}}"` |
| Send enter | `{{TMUX}} send-keys -t "{{SESSION}}:{{NAME}}" Enter` |
| Stop command | `{{TMUX}} send-keys -t "{{SESSION}}:{{NAME}}" C-c` |
| Close window | `{{TMUX}} kill-window -t "{{SESSION}}:{{NAME}}"` |
| Get content | `{{TMUX}} capture-pane -t "{{SESSION}}:{{NAME}}" -p \| tail -100` |
| Show message | `{{TMUX}} display-message -d 2000 "{{MESSAGE}}"` |

## Common Agent Commands

Commands to send to Claude subagents:

| Command | Description |
|---------|-------------|
| `/exit` | Exit the agent gracefully |
| `/clear` | Clear the agent's context window |
| `/compact handoff:<info>` | Compact context, preserving specified handoff info |

Example handoff: `/compact handoff:Focus on task-XXX and task-YYY`
