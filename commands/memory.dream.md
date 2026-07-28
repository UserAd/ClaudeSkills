---
description: Consolidate durable project memory from recent Claude/Codex/pi sessions
---

# /memory.dream — Memory Consolidation

You consolidate durable project memory from recent **file-based** CLI sessions
(Claude, Codex, pi) for this project. You read transcripts, extract candidate
durable facts, get the developer's confirmation, then hand the confirmed facts
to `/librarian` (project memory) and the `architecture` skill (architecture
artifacts). You never write `.specify/memory/` or `.architecture/` yourself.

This command is **manual**. The user intentionally started it and is watching.
Run the phases in order; stop where a phase says STOP.

## User Input

```text
$ARGUMENTS
```

`$ARGUMENTS` may pre-seed answers and skip a gate. Recognized hints:

- source: `claude` | `codex` | `pi` | `all`
- window: `24h` | `7d` | `30d` | a `YYYY-MM-DD` lower bound (optionally `..YYYY-MM-DD` upper)

If a hint is present and unambiguous, use it and skip that gate. The confirmation
gate (Phase 4) is **never** skipped — durable change always requires the watching
developer's explicit selection (I-02).

## Hard invariants (apply to every phase)

| ID | Rule |
|----|------|
| I-01 | Session files are READ-ONLY. Use only Read/Grep/the helper. Never write, move, or rewrite a transcript. |
| I-02 | No durable change without explicit Phase-4 confirmation. |
| I-03 | Persistence ONLY via `/librarian` (`.specify/memory/`) + the `architecture` skill (`.architecture/`). NEVER write project knowledge to the user-level auto-memory dir. |
| I-04 | Never surface or propagate secrets/credentials from transcripts. Do not paste tokens, passwords, keys, or FQDNs into candidates or the packet. Do not bypass the librarian's scrubber gate. |
| I-05 | Manual only. Do not schedule, loop, or background this command. |
| I-06 | Every persisted item cites ≥1 source session id. A candidate with no `sources` is not eligible. |

---

## Phase 0 — Scope

Determine source(s) and window. If `$ARGUMENTS` supplied both unambiguously, skip
to Phase 1 and echo the resolved scope. Otherwise ask with **`AskUserQuestion`**:

- Question 1 — **Session source**: options `claude`, `codex`, `pi`, `all`
  (default `all`).
- Question 2 — **Time window**: options `24h` (default), `7d`, `30d`, `custom`.
  If `custom`, ask the developer for an absolute `YYYY-MM-DD` lower bound (and
  optional upper bound).

Map the window choice to a `--since` bound: `24h`/`7d`/`30d` pass through verbatim;
`custom` passes the absolute date(s). Default when nothing is given: `--source all
--since 24h` (FR-004).

---

## Phase 1 — Discover

Run the helper (read-only enumeration; it never reads conversational content):

```bash
scripts/memory/sessions.sh list --source <s> --since <w> [--until <u>]
```

- Consume the JSONL on stdout. Each line is one normalized session record:
  `source, id, path, started_at, mtime, size_bytes, ts_source` (newest-first).
- Capture **stderr** — it carries per-source diagnostics (skipped / empty / absent
  sources). Exit `0` = ok (including zero matches); `2` = bad usage; `3` = no
  source available.

**Phase 1a — Empty (FR-012, SC-004)**: if stdout has zero records, report
`Nothing to consolidate — no sessions in <window> for <source(s)>` and **STOP**.
No analysis, no handoff.

**Phase 1b — Skips (FR-013)**: for any source the helper reported missing or
empty on stderr, note the omission in the final report and continue with the
remaining sources. Never fail the run because one source is absent.

Summarize the discovered set: count per source, window, newest/oldest
`started_at`.

---

## Phase 2 — Analyze

Read **high-signal** sessions only — newest first, sample, do NOT read every file
exhaustively (FR-006). Prefer larger / more-recent transcripts and those likely to
carry decisions. Use `Read` and `Grep` on the `path` values from Phase 1
(transcripts stay read-only — I-01).

Hunt for durable signal, porting the original dream intent:

- **User-stated rules**: "always", "never", "remember", "rule", "don't" (and the
  same in the user's working language if the transcript shows another language).
- **Decisions**: "decided", "decision", "tradeoff", "because", "instead of".
- **Repeated evidence**: the same error text, failed command, file path, or
  procedure recurring across turns or sessions.
- **Gotchas**: debugging traps, surprising failures, non-obvious fixes.

Extract **durable-fact candidates** (data-model E3). Each candidate:

| Field | Value |
|-------|-------|
| `category` | `rule` \| `decision` \| `knowledge` \| `pattern` \| `gotcha` |
| `content` | 1–3 dense lines |
| `evidence` | the user statement / repeated signal / decision that supports it |
| `sources` | cited session id(s) — non-empty (I-06) |
| `date` | absolute `YYYY-MM-DD`; convert "yesterday"/"today" using session `started_at` (FR-016) |
| `target` | `librarian` (project fact) \| `architecture` (service/decision/contract) \| `both` |
| `dedupe` | `new` \| `update-existing` \| `skip-duplicate` |

**Promotion bar**: promote only on an explicit user statement, a clear design
decision, or repeated cross-session evidence. Drop one-off, low-signal noise.

**Dedupe (FR-011)**: read the relevant `.specify/memory/` files **read-only**
(start at `.specify/memory/index.md`, then the matching `<service>/` docs) and the
`.architecture/` registries. Mark each candidate `new`, `update-existing`, or
`skip-duplicate`. Do not propose a duplicate of an existing entry.

**Secrets (I-04)**: if a candidate's evidence contains a secret/credential/token,
redact it to a description ("DB password set via env") — never carry the literal
value forward.

**Packaging candidates (out of scope here)**: if you notice a repeated *manual
workflow* worth packaging into a skill/subagent/command, note it as **one line**
pointing to the `memory-distill` skill. Do NOT create any asset in this command —
that is distill's job. Stay focused on memory consolidation.

---

## Phase 3 — Present

Show the candidate list to the developer. For each candidate display: category,
content, target (`librarian`/`architecture`/`both`), dedupe status, the cited
**session id(s)**, and the absolute **`YYYY-MM-DD`** date (FR-016, SC-005). Group
by target so the routing is obvious. If there are zero qualifying candidates after
analysis, say so and **STOP** (clean exit, no handoff).

## Phase 4 — Confirm

Use **`AskUserQuestion`** to let the developer select which candidates to keep.
For a short list, one multi-select question; for a longer list, batch by target or
category. This gate is mandatory and never skipped (I-02, FR-008, SC-007).

- The developer's selection is authoritative. Discard everything not selected.
- **If nothing is confirmed**: exit cleanly — no packet, no `/librarian`, no
  `architecture` invocation, no changes (Acceptance Scenario 3).

---

## Phase 5 — Handoff

Only reached when ≥1 candidate is confirmed. Persistence happens ONLY through the
maintainers (I-03, FR-009, FR-017) — this command writes nothing into
`.specify/memory/` or `.architecture/` directly.

1. **Write the handoff packet** to `/tmp/memory-dream-handoff-<ts>.md` where
   `<ts> = $(date +%Y%m%d-%H%M%S)`. Packet contents (data-model E5):

   - `command: dream`
   - `window: { since, until }` — the analyzed range
   - `sources_used` — sources actually read (exclude skipped ones)
   - `memory_items` — confirmed E3 facts routed to `/librarian`; each with
     category, content, absolute date, dedupe status, and cited session id(s)
   - `architecture_items` — confirmed facts routed to `architecture` (services,
     decisions, contracts), each with cited session id(s)
   - Re-verify before writing: every item cites ≥1 session id (I-06); no secrets
     present (I-04); contains only Phase-4-confirmed items (SC-007).

2. **Hand off to `/librarian`** (project memory → `.specify/memory/`). Invoke
   `/tmux librarian` with a task that points at the packet path and the
   `memory_items`. The librarian owns markdownlint + the scrubber gate — do not
   replicate or bypass them (I-04). Per `.claude/commands/librarian.md`, the
   librarian writes only to `.specify/memory/`, refreshes `index.md`, lints, runs
   the scrubber audit, and signals completion; do not wait on it.

3. **Hand off to `architecture`** (architecture artifacts → `.architecture/`).
   Only if `architecture_items` is non-empty: invoke the `architecture` skill,
   passing the packet path and those items, so it creates/updates the relevant
   domain/service/contract registries. Do not edit `.architecture/` yourself.

If `memory_items` is empty, skip step 2; if `architecture_items` is empty, skip
step 3.

---

## Phase 6 — Report

Return a brief summary:

- **Confirmed / handed-off**: count routed to `/librarian` and to `architecture`.
- **Skipped sources**: any source omitted in Phase 1b and why.
- **Sources used**: which sources were actually read.
- **Window**: the analyzed range (absolute dates).
- **Packet**: the `/tmp/memory-dream-handoff-<ts>.md` path.
- **Workflow candidates**: at most a one-line pointer to the `memory-distill`
  skill if a packaging candidate was noticed.

"Nothing to consolidate" (Phase 1a) and "nothing confirmed" (Phase 4) are valid,
successful terminal states.
