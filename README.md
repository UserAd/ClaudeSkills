# Claude Code Skills

A collection of custom skills for Claude Code.

## Available Skills

| Skill | Description |
| ----- | ----------- |
| [codex-assistant](skills/codex-assistant/) | Delegate tasks to OpenAI Codex CLI for code analysis, generation, and review. Runs in read-only sandbox mode. |
| [ears-translator](skills/ears-translator/) | Translate user stories and informal requirements into EARS (Easy Approach to Requirements Syntax) format. |
| [kamailio-config](skills/kamailio-config/) | Kamailio SIP server configuration and troubleshooting. Includes pseudo-variables reference, module docs, and syntax validation via Docker. |
| [tmux](skills/tmux/) | Orchestrate Claude subagents in tmux windows for parallel task execution. Works best with [agentmail](https://github.com/userAd/agentMail/) for async notifications. |

## Commands

Slash commands for common workflows. Copy to `.claude/commands/`.

| Command | Description |
| ------- | ----------- |
| [collegial-review](commands/collegial-review.md) | Spawn multiple AI agents (Codex, Minimax, Claude) via tmux to review implementation changes. Uses agentmail for coordination. |
| [ears-artifacts](commands/ears-artifacts.md) | Validate plan artifacts using the ears-translator skill. |
| [git-commit](commands/git-commit.md) | Create git commit comparing current branch with main, generate PR message to `/tmp/{branch}-pr.md`. |

## Installation

Copy skills to `.claude/skills/` and commands to `.claude/commands/`:

```bash
cp -r skills/tmux /path/to/your/project/.claude/skills/
cp commands/git-commit.md /path/to/your/project/.claude/commands/
```

## Usage

Skills are automatically activated based on trigger keywords in your prompts.
See each skill's `SKILL.md` for details.
