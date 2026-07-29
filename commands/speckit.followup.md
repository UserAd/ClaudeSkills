---
description: Turn a follow-up request for an already-implemented feature into clarified spec/plan/tasks updates, appending one or more new phases, then hand off to phase-implement.
handoffs:
  - label: Implement the follow-up phase
    agent: phase-implement
    prompt: Implement the next (follow-up) phase of this feature, then stop.
---

## User Input

```text
$ARGUMENTS
```

The follow-up request. You **MUST** treat this as the change to fold into the
active feature. If empty, ask the user what the follow-up is before proceeding.

## Purpose

A feature already has `spec.md` / `plan.md` / `tasks.md` (and usually shipped
phases). The user wants a follow-up (a fix, an addition, a DX improvement, a
gap found in review). This command does NOT implement it — it CLARIFIES the
request, folds it into the existing spec/plan/tasks, APPENDS one or more new
phases to `tasks.md`, and suggests `/phase-implement` to execute them.

It only ever APPENDS. It never renumbers, rewrites, or re-opens existing phases
or their task markers.

## Resolve FEATURE_DIR

Run once, from repo root. Absolute paths.

```bash
.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks
```

Parse `FEATURE_DIR`, `FEATURE_SPEC`, `TASKS`. Derive `PLAN=$FEATURE_DIR/plan.md`.
For single quotes in args like "I'm Groot", escape: `'I'\''m Groot'`.

- No `FEATURE_DIR` (empty / not a feature branch) → STOP. Tell the user to
  checkout a feature branch or run `/speckit.specify`.
- Missing `plan.md` or `tasks.md` → STOP. This is a follow-up on an existing
  feature; tell the user to run `/speckit.plan` + `/speckit.tasks` first (use
  `/speckit.specify` for a brand-new feature instead).

## Steps

1. **Load project memory + context**: read `.specify/memory/constitution.md` if
   present. Read `.specify/memory/index.md` and each file it lists (domain
   knowledge, conventions, lessons). Skip silently if absent. Read `spec.md`,
   `plan.md`, and `tasks.md` in full — you must understand the current scope,
   tech context, phase index, and the highest existing phase and task IDs before
   changing anything.

2. **Compute append anchors** from `tasks.md`:
   - `LAST_PHASE` = the highest `[N]` in the `<index>` block.
   - `LAST_TASK` = the highest `T###` across all `<phase_*>` blocks.
   - New phase(s) start at `LAST_PHASE + 1`; new tasks continue from
     `LAST_TASK + 1`. Never reuse a number.

3. **Clarify the follow-up** (interactive, targeted, ≤5 questions). Only ask what
   materially changes scope, decomposition, acceptance, or risk. Prefer
   `AskUserQuestion` (one call, batched). For each question offer a
   **recommended** option first with 1–2 sentences of reasoning. Cover, as
   relevant and still unclear:
   - **Scope & boundary**: exactly what changes; what is explicitly out of scope.
   - **Acceptance / done**: the observable, testable outcome that means "done".
   - **Decomposition**: is this ONE cohesive phase, or several independent
     phases? (Split only when the parts are independently testable and touch
     unrelated surfaces; otherwise keep it one phase.)
   - **Constraints**: new tech/deps/files, or reuse existing? gates to run.
   Stop early once the request is unambiguous. If `$ARGUMENTS` is already
   precise, ask nothing and say so.

4. **Update `spec.md`** (minimal, testable, additive):
   - Ensure a `## Follow-ups` section exists (create it after the main
     Requirements/Success Criteria sections if missing).
   - Under it add `### <YYYY-MM-DD> — <short title>` with: the clarified request,
     any `- Q: … → A: …` clarification bullets, and 1+ testable
     acceptance bullets (new FRs / success criteria phrased so a spec/test can
     verify them). Do NOT rewrite unrelated sections or restate the whole spec.
   - If the follow-up corrects a defect in shipped scope, say so plainly (what
     was wrong, what "correct" now means).

5. **Update `plan.md`** (only if the follow-up touches tech/structure):
   - If it introduces new stack, dependencies, files, or constraints, extend the
     `<tech_context>` block and the Project Structure list; add a one-line entry
     under Recent Changes / Active Technologies if the plan tracks them.
   - If it is purely a fix within the existing plan, add a short note to the
     relevant section rather than inventing new tech. If nothing plan-level
     changes, state that explicitly and leave `plan.md` untouched.

6. **Update `tasks.md`** — APPEND the new phase(s). For each new phase `N`
   (starting at `LAST_PHASE + 1`), matching the file's existing conventions:
   - Add one line `[ ] [N] <concise phase name>` immediately BEFORE the
     `</index>` tag. Leave every existing `<index>` line byte-for-byte unchanged
     (their `[x]`/`[~]`/`[ ]` markers are owned by `context.cjs start|finish`).
   - Add a `## Phase N: <name>` section, then a `<phase_N> … </phase_N>` block
     containing: a **Purpose** line; a **Tech Context** subsection (Stack for
     this phase / bases / **Memory files** to read / **Gate** command(s)); the
     task list as `- [ ] T### <description with concrete file paths>` continuing
     the `T###` sequence; and a closing **Checkpoint** line stating the
     observable success condition. Mark parallel-safe tasks `[P]`.
   - Insert the new phase section(s) AFTER the last existing `## Phase …` block
     and BEFORE `## Dependencies & Execution Order` (or at the end of the phase
     sections if that heading is absent). Order multiple new phases by
     dependency.
   - Keep tasks TDD-shaped where tests apply (test task before its
     implementation task) and name real files, mirroring how earlier phases in
     this same `tasks.md` are written.

7. **Validate**:
   - `node .specify/scripts/context.cjs phase` now returns the FIRST new phase
     number (`LAST_PHASE + 1`) — proves the `<index>` append is well-formed and
     no existing phase was disturbed.
   - `node .specify/scripts/context.cjs context <N>` for each new phase surfaces
     its `<phase_N>` goal + `T###` list.
   - Run `markdownlint-cli2 --config .specify/memory/.markdownlint.jsonc` on
     `tasks.md`/`spec.md`/`plan.md` if the repo lints memory/spec markdown; fix
     new findings only.
   - Confirm no existing `[x]`/`[~]` marker or prior `T###` changed (diff-check).

8. **Report + hand off**:
   - What was clarified (Q/A), and the spec/plan/tasks deltas (sections touched).
   - The new phase(s): number, name, task IDs, and the gate each will run.
   - Suggest execution, one phase per run:

     ```text
     /phase-implement <N>      # run the first new phase, then stop
     /phase-implement          # re-run for each subsequent phase
     ```

   - Note the repo Git rule (commit locally per phase; never push/merge unless
     the user asks). This command writes docs only — it does not implement.

## Rules

- APPEND-ONLY. Never renumber, delete, or rewrite existing phases, tasks, or
  `<index>` markers. New phases enter the index as `[ ]`; `context.cjs` moves
  their markers during implementation.
- Requires an existing `spec.md` + `plan.md` + `tasks.md`. It is NOT for new
  features (`/speckit.specify`) or first-time task generation (`/speckit.tasks`).
- One follow-up may yield ONE phase (default) or SEVERAL — split only when the
  parts are independently testable; the clarification decides.
- Keep spec/plan edits minimal and testable; do not restate or reorder unrelated
  content. Preserve heading hierarchy and formatting.
- Do NOT implement the phase(s) here and do NOT run `context.cjs start|finish`.
  Authoring only; `/phase-implement` executes.
- DO NOT push or merge (repo Git rule). Communication: Absolute Mode (blunt, no
  filler) per repo CLAUDE.md.
