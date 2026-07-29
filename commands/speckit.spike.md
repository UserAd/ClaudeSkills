---
description: Spike an idea through experiential exploration — decompose it into Given/When/Then questions, build runnable experiments, and record verdicts. Run with no argument for frontier mode (propose what to spike next), or --wrap-up to package findings into a project skill. Use when validating a risky/uncertain idea before writing a full spec.
---

# /speckit.spike — Experiential Idea Validation

Spike an idea by building focused experiments that prove or kill feasibility, then
produce verified knowledge for the real build. Adapted from the GSD spike workflow to
this repo's conventions: artifacts live under `.specify/spikes/`, each spike is
committed locally (never pushed unless asked), and `--wrap-up` packages findings into
a `spike-findings-<project>` skill.

This command is **manual and watched** — the user intentionally started it and is
following along. You have bash for inspection/building; use it carefully and never
push to git.

## User Input

```text
$ARGUMENTS
```

## Mode Routing

Parse the first token of `$ARGUMENTS`:

- `--wrap-up` → strip the flag, run **Wrap-Up Mode**.
- empty, or `frontier`, or "what should I spike?" → run **Frontier Mode**.
- anything else → run **Idea Mode** with all of `$ARGUMENTS` as the idea.

Flags (idea mode): `--quick` skips decomposition + alignment and builds the idea as a
single spike. (`--text` is not supported — always use `AskUserQuestion`.)

`<project>` throughout = the repo root directory name (`basename "$(git rev-parse
--show-toplevel)"`, e.g. `my-monorepo`).

---

## Shared Foundations (all modes)

### Spike location & numbering

- Spike artifacts live under `.specify/spikes/`. Auto-create it when missing:
  `mkdir -p .specify/spikes`.
- Per-spike directory: `.specify/spikes/NNN-descriptive-name/` (3-digit, zero-padded).
- Next number = highest existing + 1 (use `find`, not a bare glob — zsh errors on a
  no-match glob and the project shell is zsh):
  `find .specify/spikes -maxdepth 1 -type d -name '[0-9][0-9][0-9]-*' 2>/dev/null | sort | tail -1`.
- **Comparison spikes** (same question, different approaches) share a number with a
  letter suffix: `NNN-a-name/`, `NNN-b-name/`.
- `.specify/spikes/MANIFEST.md` indexes all spikes; `.specify/spikes/CONVENTIONS.md`
  records recurring stack/structure/patterns.

### Re-ground before each spike

Re-read `.specify/spikes/MANIFEST.md` and `.specify/spikes/CONVENTIONS.md` before
starting each spike (not just the first) to prevent drift in long sessions. Honor the
manifest Requirements — a spike must not contradict an established requirement.

### Stack selection

Follow `.specify/spikes/CONVENTIONS.md` if it exists. Otherwise detect the project
stack (`Gemfile`, `package.json`, `pyproject.toml`, `go.mod`) and default to it; use
`bin/dev` when a real service is exercised. For greenfield experiments pick whatever
reaches a runnable result fastest. **Avoid** containers, bundlers/build tooling, and
env/config systems — hardcode config inside the spike.

### Git & document gates (apply before every commit)

- Commit each spike LOCALLY after it completes; one commit per spike. **Never `git
  push` and never open an MR unless the user explicitly asks.**
  `git add .specify/spikes/NNN-name/ .specify/spikes/MANIFEST.md && git commit -m
  "docs(spike-NNN): [VERDICT] — <key finding>"`.
- Before committing ANY persisted doc, run the gates on the new/changed files and do
  not commit while either reports findings:
  - `python3 .claude/skills/scrubber/scripts/scrub.py --audit`
  - `markdownlint-cli2 --config .specify/memory/.markdownlint.jsonc "<file>"`
- Never write literal home paths or secrets into committed docs — use `$HOME` /
  `<user>` placeholders. Never write project knowledge to the user-level auto-memory
  directory.

### Artifact schemas

**`.specify/spikes/MANIFEST.md`**

```markdown
# Spike Manifest

## Idea
[one paragraph describing the overall idea]

## Requirements
[emergent non-negotiable design decisions; append as they surface]

## Spikes
| # | Name | Type | Validates | Verdict | Tags |
|---|------|------|-----------|---------|------|
```

**`.specify/spikes/NNN-name/README.md`** — YAML frontmatter (`spike`, `name`, `type`,
`validates`, `verdict` ∈ PENDING|VALIDATED|INVALIDATED|PARTIAL, `related`, `tags`)
then sections: `## What This Validates` (G/W/T) · `## Research` (omit if no external
dep) · `## How to Run` · `## Observability` (omit if none) · `## Investigation Trail`
(updated each iteration) · `## Results` (verdict + evidence + surprises).

**`.specify/spikes/CONVENTIONS.md`** — `## Stack` · `## Structure` · `## Patterns` ·
`## Tools & Libraries`. Only patterns in 2+ spikes or explicitly user-chosen.

---

## Idea Mode

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 SPECKIT ► SPIKING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Phase 0 — Setup & prior context

1. Create `.specify/spikes/` if missing; determine the next spike number.
2. If `.specify/spikes/` already has content, load prior context in order:
   `CONVENTIONS.md`; any `.claude/skills/spike-findings-*/SKILL.md` + their
   `references/*.md`; `MANIFEST.md`; the READMEs of prior spikes related to this idea
   (match tags/names/tech). Skip already-validated questions, build on prior findings,
   don't repeat failed approaches, follow established conventions (note any deviation).

### Phase 1 — Decompose

**If `--quick`:** skip decomposition + alignment; take the idea as one spike at the
next number; jump to Phase 3.

Break the idea into 2-5 independent questions, each framed Given/When/Then. Present a
table; order by risk (most idea-killing first):

```
| # | Spike | Type | Validates (Given/When/Then) | Risk |
|---|-------|------|-----------------------------|------|
```

`standard` = one approach, one question. `comparison` = same question, different
approaches (shared number + letter suffix). Good spikes have observable output; reject
"too broad / no observable output / just reading".

### Phase 2 — Align (checkpoint)

Use `AskUserQuestion`: build all spikes in this order, or adjust the list? Wait for
the decision before building. (Skipped under `--quick`.)

### Phase 3 — Research (per spike, before building)

Present a 2-3 sentence briefing. Research current state of the art: context7
(`resolve-library-id` → `query-docs`) for libraries/frameworks; `WebSearch`/`WebFetch`
for APIs/services without a context7 entry. Surface competing approaches as a table
and state the chosen approach. Record findings in the README `## Research` section. If
2+ credible approaches exist, plan quick variants to compare. **Skip** for pure-logic
spikes with no external dependency.

### Phase 4 — Build (depth over speed)

Create `.specify/spikes/NNN-name/`. **Default to building something the user can
experience** — a small HTML page, a web UI with a button, a page showing data flowing
— not stdout only. Fall back to stdout/CLI only for pure facts (does it parse? does
the API authenticate? benchmark numbers).

If the spike needs runtime observability (concurrency, timing, streaming, network),
build a forensic log layer: an event-log array with ISO timestamps + category tags, an
export mechanism (server → GET endpoint; CLI → JSON file; browser → Export button),
and a log summary (counts, duration, errors).

Start simplest, then deepen. Iterate when findings warrant: probe edge cases (large
inputs, concurrency, malformed data, failures); follow surprises; note pivots in the
README. Multiple files per spike are expected for complex questions. Comparison spikes:
build back-to-back, then a head-to-head comparison.

### Phase 5 — Verify & verdict

- Self-verifiable: run it, iterate if findings warrant deeper investigation, set the
  verdict.
- Needs human judgment: present a checkpoint —

  ```
  ╔══════════════════════════════════════════════════════════════╗
  ║  CHECKPOINT: Verification Required                           ║
  ╚══════════════════════════════════════════════════════════════╝
  Spike {NNN}: {name}
  How to run: {command}
  What to expect: {concrete outcomes}
  ```

  Ask (via `AskUserQuestion`) whether it matches expectations; do NOT self-declare.

Record the verdict (VALIDATED / INVALIDATED / PARTIAL) plus the investigation trail and
evidence in the README `## Results`. **Never declare VALIDATED from a single happy-path
run** — a verdict with no nuance is almost always incomplete.

If a core assumption is invalidated, present a decision checkpoint via
`AskUserQuestion`: continue with remaining spikes / pivot approach / abandon.

### Phase 6 — Manifest & commit

Update the `MANIFEST.md` spike row and append any emergent requirement the user
expressed during this spike. Then commit the spike locally (see Git & document gates):
`docs(spike-NNN): [VERDICT] — <key finding>`. Auto-link related spikes silently.

Report per spike:

```
◆ Spike NNN: {name}
  Verdict: {VALIDATED ✓ / INVALIDATED ✗ / PARTIAL ⚠}
  Key findings: {investigation trail, surprises, edge cases — not just the verdict}
  Impact: {effect on remaining spikes}
```

### Phase 7 — Conventions & final report

After all spikes this session, update `.specify/spikes/CONVENTIONS.md` with patterns
that emerged (only 2+ occurrences or user-chosen); commit
`docs(spikes): update conventions`. Then present:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 SPECKIT ► SPIKE COMPLETE ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Verdicts table · Key discoveries · Feasibility assessment · Signal for the build.

**▶ Next up:** `/speckit.spike --wrap-up` (package findings), `/speckit.spike` (frontier
mode / spike more), or `/speckit.specify` (start the real spec).

---

## Frontier Mode

Propose what to spike next from the existing landscape.

1. If no `.specify/spikes/` exists, say there's nothing to analyze and offer to start
   from an idea (`/speckit.spike <idea>`). Stop.
2. Load: `MANIFEST.md` (idea, requirements, verdicts); any
   `.claude/skills/spike-findings-*/SKILL.md` + `references/*.md`; `CONVENTIONS.md`; all
   `.specify/spikes/*/README.md`.
3. **Integration spikes** — review pairs/clusters of VALIDATED spikes for: shared
   resources tested independently; data handoffs assumed compatible but never proven;
   timing/ordering dependencies; resource contention. Present concrete proposed spikes
   with names + Given/When/Then. If none, say so and skip.
4. **Frontier spikes** — think laterally about the MANIFEST idea: gaps in the vision,
   discovered dependencies, alternative approaches for PARTIAL/INVALIDATED spikes,
   adjacent capabilities, comparison opportunities. Number from the highest existing
   spike, with Given/When/Then and risk ordering.
5. Present all candidates and ask (via `AskUserQuestion`) which to run. On selection,
   append the chosen spikes to `MANIFEST.md` and build them starting at Idea-Mode
   Phase 3.

---

## Wrap-Up Mode (`--wrap-up`)

Package spike findings into a project-local `spike-findings-<project>` skill — an
implementation blueprint that auto-loads in future build conversations.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 SPECKIT ► SPIKE WRAP-UP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Gather

1. Read `.specify/spikes/MANIFEST.md` (idea + requirements).
2. Glob `.specify/spikes/*/README.md`, parse frontmatter.
3. If `.claude/skills/spike-findings-<project>/SKILL.md` exists, read its
   `## Processed Spikes` list and exclude those (append mode); else all are candidates.
4. If no unprocessed spikes: report "No unprocessed spikes found in `.specify/spikes/`.
   Run `/speckit.spike` first." and stop.

Present the inventory being processed (with verdicts). Every spike carries forward —
VALIDATED → proven patterns, PARTIAL → constrained patterns, INVALIDATED → landmines.

### Group & synthesize

Group spikes by feature area (tags, names, `related`, content). Each group → one
`references/<feature-area>.md` written as an **implementation blueprint** (a recipe, not
a research paper):

```markdown
# [Feature Area]
## Requirements        # non-negotiables from MANIFEST that apply here
## How to Build It     # steps + key code snippets extracted from spike source (proven)
## What to Avoid       # gotchas, anti-patterns, dead ends tried and failed
## Constraints         # rate limits, version requirements, incompatibilities
## Origin              # synthesized from spikes NNN, NNN; sources in sources/NNN-name/
```

### Copy sources

For each included spike, copy `README.md` + the core source files into
`.claude/skills/spike-findings-<project>/sources/NNN-spike-name/`. Exclude
`node_modules/`, `__pycache__/`, `.venv/`, build artifacts, lockfiles, `.git/`,
`.DS_Store`.

### Write the skill

Create/update `.claude/skills/spike-findings-<project>/SKILL.md`:

```markdown
---
name: spike-findings-<project>
description: Implementation blueprint from spike experiments — requirements, proven patterns, and verified knowledge for building <project>. Auto-loads during implementation work. Use when building features the spikes validated.
---

## Project: <project>
[one-paragraph idea from MANIFEST]
Spike sessions wrapped: [date(s)]

## Requirements
[copied from MANIFEST Requirements — non-negotiable]

## Feature Areas
| Area | Reference | Key Finding |
|------|-----------|-------------|

## Processed Spikes
- NNN-spike-name
```

### Finalize

- Write `.specify/spikes/WRAP-UP-SUMMARY.md` (date, count, feature areas, skill path,
  processed-spikes table, key findings).
- Add a routing line to the project `CLAUDE.md` (create if missing; leave as-is if the
  line already exists):
  `- **Spike findings for <project>** (implementation patterns, constraints, gotchas) → \`Skill("spike-findings-<project>")\``
- Update `.specify/spikes/CONVENTIONS.md` with recurring patterns.
- Run the document gates (scrubber audit + markdownlint) on every written doc, then
  commit locally: `docs(spike-wrap-up): package <N> spike findings into skill`. Never
  push.

Report: processed count, feature areas, skill path, conventions/summary paths, routing
line added. **▶ Next up:** `/speckit.spike` (frontier), `/speckit.specify` /
`/speckit.plan` (real build), or `/speckit.spike <idea>`.

---

## Invariants (all modes)

- **Manual & watched** — interactive only; no background or scheduling.
- **Depth over speed** — never VALIDATED from a single happy path; human-judged spikes
  are gated by a checkpoint.
- **Local commits only** — one commit per spike; never push or open an MR unless the
  user explicitly asks.
- **Knowledge target** — wrap-up persists to the `spike-findings-<project>` skill; the
  user-level auto-memory directory is never written.
- **Gated docs** — every persisted doc passes the scrubber audit + markdownlint; no
  literal home paths.
- **Governed stacks** — spikes use the monorepo's stacks, hardcode config, avoid heavy
  infra.
