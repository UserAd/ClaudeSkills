---
name: memory-distill
description: Package repeated workflows from recent Claude/Codex/pi sessions into the smallest reusable asset (skill, subagent, or command). Use when the user wants to distill sessions, extract a skill/command from repeated work, or package a recurring workflow. Triggers on "distill", "package workflow", "extract skill from sessions", "package recurring workflow".
---

# Memory Distill — Workflow Packaging

Look back over recent sessions, find manual workflows worth packaging, and turn
only the high-confidence ones into the smallest reusable asset: a skill, a
subagent, or a command. Reuse and extend before you duplicate.

This skill is **manual and watched** — the user invoked it and is present for
every gate. Sessions are read-only evidence; the only thing this skill writes is
a single confirmed asset file plus a handoff packet. Persistence of
documentation goes through `/librarian` and `/architecture`, never directly.

**Creating nothing is a valid, successful outcome.** If no workflow has actually
been repeated, say so and stop — do not manufacture an asset to justify the run.

## Quick Start

```bash
# Discover sessions (read-only). Bound = 24h | 7d | 30d | YYYY-MM-DD.
scripts/memory/sessions.sh list --source all --since 30d

# Single source
scripts/memory/sessions.sh list --source claude --since 7d
scripts/memory/sessions.sh list --source codex  --since 2026-06-01

# What sources exist at all
scripts/memory/sessions.sh sources
```

JSONL out, newest-first, fields: `source,id,path,started_at,mtime,size_bytes,
ts_source`. Diagnostics (skipped/empty sources) on stderr. Exit `0` ok (incl.
zero matches), `2` bad usage, `3` no source available.

## Phase 0 — Scope (gate)

`AskUserQuestion` for two choices:

1. **Source**: `claude` | `codex` | `pi` | `all`.
2. **Window**: `24h` (feature default, FR-004) | `7d` | `30d` | custom
   (`YYYY-MM-DD`). Distill's original default was 30 days — offer it
   prominently as the recommended depth for finding repeated workflows, but the
   skill's default when no answer is given stays `24h`.

If the invocation pre-seeds source/window (e.g. via arguments), skip the gate
and use the seeded values.

## Phase 1 — Discover

Run the helper for the chosen source + window:

```bash
scripts/memory/sessions.sh list --source <source> --since <window> [--until <bound>]
```

- Consume the JSONL. Records are already sorted newest-first; cite `id`.
- **Empty** (zero records): report **"nothing to distill"** and **STOP**. No
  inventory, no analysis, no handoff (FR-012, SC-004).
- **Skipped sources**: read stderr; note any missing/empty source in the final
  report and continue with the rest (FR-013). Helper exit `3` means no source
  is available at all — report and stop.

## Phase 2 — Inventory existing assets FIRST

Before proposing anything, know what already exists so you reuse or extend
rather than duplicate (FR-011). Glob and read name + description of each:

```text
.claude/skills/**/SKILL.md     # skills
.claude/agents/*.md            # subagents
.claude/commands/*.md          # commands
```

Record what each asset already covers. A candidate an existing asset already
handles is `extend-existing` or `skip`, never a new duplicate.

## Phase 3 — Analyze sessions for repeated workflows

Read the listed sessions by their `path` (Read/Grep). Sample high-signal, newest
first — do **not** read every file exhaustively (FR-007, large/numerous sessions
edge case).

Look broadly for work that is repeated, time-consuming, error-prone,
context-heavy, or benefits from a consistent process — across coding, research,
ops, planning, analysis. Strong signals:

- repeated command/tool sequences across sessions;
- repeated file paths or repeated error→fix cycles;
- user phrases like "again", "every time", "like last time", "the usual",
  "same as before" (also in the user's working language if the transcript shows
  another language).

**Action bar — a candidate is real only when it:**

- occurred **≥2 times**, or is clearly likely to recur **and** costly to repeat;
- has stable inputs, a repeatable procedure, and a clear stopping condition;
- would materially improve speed, quality, consistency, or reliability;
- is **not** already covered by an existing asset (else `extend-existing`/`skip`).

## Phase 4 — Present shortlist (gate)

Build a compact shortlist. For each candidate (data-model **E4**) show:

| Field | Content |
|-------|---------|
| `workflow` | one-line description |
| `evidence` | cited session ids `[id]` + absolute dates (YYYY-MM-DD) |
| `frequency` | occurrences (≥2) or `likely-recurring-costly` |
| `confidence` | `high` \| `medium` \| `low` |
| `form` | `skill` \| `subagent` \| `command` \| `extend-existing` \| `skip` |
| `existing_asset` | path, when `form = extend-existing`/`skip` |
| `rationale` | why it is / isn't worth creating |

Convert every relative date to absolute YYYY-MM-DD (FR-016, I-06). Then
`AskUserQuestion`: the user selects which candidate(s) to package. **Selecting
none is a clean exit** — proceed to Phase 6 and report "created nothing"
(I-02, FR-008, SC-007).

## Phase 5 — Create the smallest-form asset

For each **confirmed** candidate, pick the smallest appropriate form and write
it under the existing project convention:

| Form | Path | Frontmatter |
|------|------|-------------|
| skill | `.claude/skills/<name>/SKILL.md` | `name` + trigger-rich `description` |
| subagent | `.claude/agents/<name>.md` | `description` (+ optional `model`/`tools`) + system-prompt body |
| command | `.claude/commands/<name>.md` | `description`; body uses `$ARGUMENTS`/`$1` |

Rules:

- Match the tone and structure of comparable existing assets (Quick Start /
  phases / clear stopping condition). Keep each asset focused on **one** workflow.
- Do not create speculative, overlapping, or overly broad assets.
- Assets only **describe** procedures — never create accounts, send messages,
  change permissions, or take irreversible external action.

**Validate after writing** (distill.txt Phase 6): Glob every referenced file
path and Grep every referenced function/class name to confirm they exist.

## Phase 6 — Handoff + report

Write the handoff packet (data-model **E5**) to
`/tmp/memory-distill-handoff-<timestamp>.md` containing only user-confirmed
items:

```text
command: distill
window: { since, until }
sources_used: [ ... ]
assets_created: [ <paths to new/changed asset files> ]
architecture_items: [ <items with architectural impact> ]
```

Then hand off:

- **Asset documentation** → `/librarian` (writes `.specify/memory/`, owns
  markdownlint + scrubber gates), passing the packet path.
- **Architectural impact** → `/architecture` (writes `.architecture/`), if any.

This skill does **not** write `.specify/memory/` or `.architecture/` itself.

Final report:

- **Shortlist** considered, with evidence/frequency/confidence/recommended form.
- **Created or extended**: asset paths + one-line purpose. If nothing met the
  bar: **"Created nothing — no repeated workflow worth packaging"** — a complete,
  successful result (US2 AC3).
- **Skipped**: what was deliberately not packaged, and why.
- **Needs more evidence**: promising candidates lacking repetition, stable
  inputs, or a clear stopping condition.
- Sources used + window + any skipped sources.

## Invariants (never violate)

| ID | Rule |
|----|------|
| I-01 | Session files are read-only — never modify, delete, or rewrite (FR-005, SC-006). Use Read/Grep + the helper only. |
| I-02 | No durable change (asset write, handoff) without explicit confirmation (FR-008, SC-007). |
| I-03 | Persist documentation only via `/librarian` (`.specify/memory/`) and `/architecture` (`.architecture/`). NEVER the user-level auto-memory directory (`~/.claude/projects/*/memory/`) (FR-017). |
| I-04 | Never surface or propagate secrets/credentials from transcripts; never bypass the downstream scrubber gate (FR-014). |
| I-05 | Manual invocation only — never schedule or run in the background (FR-015). |
| I-06 | Every created asset and persisted item cites ≥1 source session id (FR-016, SC-005). |
