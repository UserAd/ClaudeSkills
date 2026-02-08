---
name: tdd-implement
description: Execute TDD implementation with a 3-agent team (QA, Implementor, Reviewer) following Red-Green-Review cycle. Use when Claude needs to (1) implement features using TDD methodology, (2) run a multi-agent team for code changes, (3) enforce minimal working code through test-driven development. Triggers on "tdd", "implement with tdd", "tdd team", "red green refactor", "tdd implement".
---

# TDD Team Implementation

## User Input

```text
$ARGUMENTS
```

Consider user input before proceeding (if not empty).

## Prerequisites

The lead shall read `.specify/memory/constitution.md` for project principles and constraints before starting.
The lead shall read spec/plan/tasks files for the current feature (if they exist).
The lead shall read `CLAUDE.md` for quality gates.

## Core Principles

Include in EVERY agent prompt. See [references/agent-rules.md](references/agent-rules.md) for full text.

Each agent shall write the smallest amount of code that satisfies requirements and tests.
Each agent shall prefer simple solutions over clever ones.
Each agent shall not add features, handling, or abstractions beyond requirements or tests.
Each agent shall not add docstrings, comments, type hints, or refactoring beyond what the task demands.
Each agent shall treat requirements as the maximum scope ceiling.

## Team

Create via TeamCreate, then spawn 3 agents:

| Role | Model | subagent_type |
|------|-------|---------------|
| qa | sonnet | general-purpose |
| implementor | sonnet | general-purpose |
| reviewer | opus | general-purpose |

## Workflow

```
RED → GREEN → QUALITY GATES → REVIEW → (REVISE loop, max 3) → DONE
```

### Phase 1: RED — Failing Tests

Assign to **qa**. Use prompt from [references/qa-prompt.md](references/qa-prompt.md).

The lead shall substitute `{REQUIREMENTS}` with requirements from user input or spec files.
When qa completes, the lead shall verify tests exist and fail via `uv run pytest tests/`.

### Phase 2: GREEN — Minimal Implementation

Assign to **implementor**. Use prompt from [references/implementor-prompt.md](references/implementor-prompt.md).

When implementor completes, the lead shall verify all tests pass.

### Phase 3: Quality Gates

The lead shall run:
```bash
uv run pytest tests/
uv run ruff format --check . --exclude examples/
uv run ruff check .
uv run pycodestyle *.py processors/ services/ tests/ alembic/env.py
```

If any quality gate fails, then the lead shall send exact error output to **implementor** for fix.

### Phase 4: Review

Assign to **reviewer**. Use prompt from [references/reviewer-prompt.md](references/reviewer-prompt.md).

The reviewer shall return PASS or REVISE with specific file:line issues.

### Phase 5: Revise (if needed)

When reviewer returns REVISE, the lead shall send specific issues to **implementor** with exact code suggestions.
The implementor shall fix only the flagged issues.
When implementor completes fixes, the lead shall re-run quality gates (Phase 3).
When quality gates pass, the lead shall re-send to **reviewer**.
If revise cycle exceeds 3 iterations, then the lead shall take over and make final fixes directly.

## Task List

The lead shall create these tasks at start:

1. `Write failing tests (RED)` — qa
2. `Implement minimal code (GREEN)` — implementor, blocked by #1
3. `Run quality gates` — blocked by #2
4. `Review changes` — reviewer, blocked by #3
5. `Apply review fixes` — blocked by #4
6. `Final quality gates and cleanup` — blocked by #5

## Error Handling

If qa writes tests that error on imports, then the lead shall instruct qa to mock missing modules so tests fail on assertions instead.
If implementor cannot make tests pass after 2 attempts, then the lead shall take over directly.
If reviewer suggests scope-expanding changes, then the lead shall reject them and request review within stated criteria only.
If any agent is unresponsive after 2 messages, then the lead shall reassign the task to itself.

## Completion

When all phases complete, the lead shall run final quality gates.
When quality gates pass, the lead shall shutdown all agents via SendMessage type: "shutdown_request".
When all agents shut down, the lead shall clean up with TeamDelete.
The lead shall report: files changed, tests added, review outcome.
