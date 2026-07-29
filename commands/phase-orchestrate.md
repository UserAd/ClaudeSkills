---
description: Drive ALL remaining spec-kit phases to done, each in an isolated phase-implementer subagent, independently verifying the gate + appending the worklog before advancing. Sequential; never pushes.
---

## User Input

```text
$ARGUMENTS
```

Optional. `--until N` → stop after phase N (default: run to the last `[ ]`).
Free text → settled design decisions / constraints to front-load into every
subagent dispatch (so isolated runs don't re-derive or diverge).

## Purpose

The multi-phase sibling of `/phase-implement`. Where `/phase-implement` runs ONE
phase and stops, this loops the `phase-implementer` subagent across EVERY
remaining phase — keeping the main context lean — and adds the discipline a raw
loop lacks: **independent gate-verification** of each subagent's claims and a
**worklog entry committed between every phase**, before advancing. Sequential:
later phases build on earlier ones, so never parallel.

## Resolve FEATURE_DIR

Run once. Absolute path (same feature `context.cjs` resolves).

```bash
FEATURE_DIR=$(.specify/scripts/bash/check-prerequisites.sh --json --paths-only \
  | sed -n 's/.*"FEATURE_DIR":"\([^"]*\)".*/\1/p')
```

Empty / not a feature branch → STOP (run `/speckit.specify` or checkout a feature
branch). Missing `tasks.md` / `<index>` → STOP, suggest `/speckit.tasks`.

## Steps

1. **Plan the run.** `node .specify/scripts/context.cjs phase` = the first
   not-started phase; read the `<index>` for the full ordered `[ ]` list up to
   `--until` (default: the last). None → report "all phases `[x]`", STOP.
   Gather the **settled decisions** to front-load: `$ARGUMENTS` text + the spec
   `## Follow-ups` (FR/SC) + what prior phases' verified outcomes established.

2. **For each not-started phase N, in order:**

   a. **Dispatch a `phase-implementer` subagent** (Task tool, `run_in_background`)
      targeting **N explicitly** (`context.cjs start N`). Front-load in the
      prompt: the settled decisions for N (so it doesn't re-derive); the
      guardrails — strict TDD (RED first), run the phase **Gate** via `bin/dev`,
      mark each `T###` `[X]`, commit locally per logical group with the repo
      co-author footer, **NEVER push**, do not touch other phases; and the
      report contract — return the **exact** gate summary line + commit SHAs +
      any deviations, and **STOP-and-report if the gate cannot pass** (never
      force green). One phase per subagent.

   b. **Wait** for completion, then **independently verify — do NOT trust the
      report** (a self-report is evidence, not proof):
      - `git log --oneline` shows the phase's commit(s);
      - the gate genuinely passed — spot-check with structural `grep`s for the
        phase's key invariants and/or a cheap re-run of the summary line
        (paste real output, evidence before claims);
      - each `T###` is `[X]` and `node .specify/scripts/context.cjs phase`
        advanced past N.

   c. **Verification fails** (gate red, missing commit, marker not moved, or the
      subagent surfaced a real defect) → **STOP**. Report the discrepancy and
      what the subagent claimed vs. what you found. Do NOT advance. If the
      subagent surfaced a genuine bug worth its own phase, say so (e.g.
      `/speckit.followup`).

   d. **Append the worklog** for N to `$FEATURE_DIR/worklog.md` — tasks covered,
      problems, solutions, a one-line summary — and commit it. The orchestrator
      OWNS the worklog: write it even if the subagent also did, and be honest
      about partial completion / deviations. Never advance without it.

   e. Advance to N+1.

3. **After the last phase:** append the final `## Summary of implementation of
   feature` to the worklog (accomplishments, major challenges + resolutions,
   deviations, final state) and commit.

4. **Report:** per-phase — gate result + commit SHAs + any deviation; the run's
   overall outcome; branch state (commits ahead, unpushed). Offer to push only
   if the user asks (repo Git rule).

## Rules

- **Sequential only.** Phases build on each other — never dispatch phases in
  parallel. One in flight at a time; verify before the next.
- **Independent verification is mandatory.** The subagent's structured report is
  a claim to check, not a result to relay. Confirm gate + commits + markers
  yourself before advancing (evidence before assertions).
- **Worklog between every phase**, final summary after the last — non-negotiable.
- **Front-load settled decisions** into each dispatch so isolated subagents stay
  consistent and don't re-derive the design.
- **Halt, don't churn.** Any gate red / verification miss / surfaced defect →
  STOP and report; never force a false green or loop indefinitely.
- Index markers move only via the subagent's `context.cjs start N` / `finish N`
  — never hand-edit `<index>`.
- **DO NOT PUSH or merge** unless the user explicitly asks (repo Git rule).
- Communication: Absolute Mode (blunt, no filler) per repo CLAUDE.md.

<!-- Provenance: distilled from claude session f9424ea5-ce20-4bb5-940d-19fe07e6ec90
(tech/media-node-engine, 2026-07-22) — this loop ran 5× (phases 8,9,10,12,11):
dispatch phase-implementer → verify gate independently → worklog → advance. -->
