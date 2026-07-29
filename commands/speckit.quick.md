---
description: Analyze a small change, generate a lightweight plan and tasks, and implement after confirmation. Refuses changes involving business logic, data migrations, new endpoints, or other complex categories.
handoffs:
  - label: Check Status
    agent: speckit.status
    prompt: Check current branch against spec
  - label: Analyze Consistency
    agent: speckit.analyze
    prompt: Run a project analysis for consistency
    send: true
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

`/speckit.quick` is a lightweight alternative to the full speckit pipeline (specify → clarify → plan → tasks → analyze → implement). It collapses the entire workflow into a single interactive session for small, well-defined changes that do not warrant full specification artifacts.

**Examples of suitable changes**: "Change button XXX color to red", "Add a tooltip to the settings icon", "Rename the 'Submit' label to 'Save'", "Fix typo in error message", "Add a new field to the user profile form", "Update the footer copyright year".

**Examples of unsuitable changes**: "Add user authentication", "Implement payment processing", "Refactor the entire API layer", "Add real-time notifications with WebSockets".

---

## Step 1: Parse Input & Validate

1. The text the user typed after `/speckit.quick` in the triggering message **is** the feature description. Assume you always have it available even if `$ARGUMENTS` appears literally below.
   - If empty: **ERROR** "No feature description provided. Usage: `/speckit.quick <description of the change>`"

2. Run `.specify/scripts/bash/check-prerequisites.sh --json --paths-only` from repo root to detect current branch state.
   - **Shell-safe quoting**: For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot"). For descriptions containing dollar signs, backticks, backslashes, exclamation marks, or double quotes, always wrap in single quotes to prevent shell expansion.
   - **If the script exits with error** (exit code 1): This means the current branch is `main` or `master` (the script runs `check_feature_branch` before outputting anything). Branch creation will be required — proceed to Step 2 (suitability check) first, then Step 3.
   - **If the script succeeds**: Parse JSON fields: `REPO_ROOT`, `BRANCH`, `FEATURE_DIR`, `FEATURE_SPEC`, `IMPL_PLAN`, `TASKS`. Note: the JSON key is `BRANCH` (not `CURRENT_BRANCH`), and there is no `HAS_GIT` field.

3. Branch state handling (only if the script succeeded — if it failed, you already know to go to Step 2 then Step 3):
   - **If on a feature branch**: Check whether `FEATURE_DIR` actually exists on disk (the script returns computed paths regardless of whether they exist). Use Glob or Read to check.
     - **If FEATURE_DIR exists and contains spec.md**: Use **AskUserQuestion** to ask:
       - **"Use existing branch"** (Recommended): Continue on this branch and add/overwrite quick artifacts. Skip Step 3, proceed to Step 2.
       - **"Create new branch"**: Proceed to Step 2 (suitability check), then Step 3 for a new branch.
     - **If FEATURE_DIR does not exist or has no spec.md**: Proceed to Step 2 (suitability check), then Step 3.

---

## Step 2: Suitability Analysis

**IMPORTANT: This step ALWAYS runs before Step 3 (branch creation).** No side effects (branch creation, file writes) may occur until suitability is confirmed. If the change is refused here, no branch or files are created.

Analyze the feature description to determine if it qualifies for the quick workflow. This is a TWO-STAGE gate: first from the description, then confirmed after codebase analysis in Step 4.

### Stage 1: Description-based screening

Evaluate the feature description against these criteria:

**SUITABLE for quick** (all should be true):
- Single concern or user story — the change addresses ONE thing a user can describe in one sentence without "and" joining unrelated goals (not multi-story)
- Estimated to touch **10 or fewer files**
- Estimated **10 or fewer tasks**
- No new database entities or migrations
- No new API endpoints or external integrations
- No new dependencies or packages
- No new security/auth/payment mechanisms
- No architectural decisions required
- No research phase needed (known technologies only)
- Clear, specific description (low ambiguity)

**HARD REFUSAL — The following categories are NEVER suitable for quick mode. You MUST refuse and redirect to the full pipeline. No user override is allowed:**

- **Business logic changes**: New workflows, state machines, approval flows, pricing rules, permission models, role-based access changes
- **Data migrations**: Schema changes, column additions/removals, data transformations, index changes, new tables or entities
- **New API endpoints**: New routes, controllers, serializers, request/response contracts
- **Authentication/authorization changes**: Login flows, token handling, session management, permission checks, OAuth integration
- **Payment/billing changes**: Payment gateway integration, subscription logic, invoice generation, refund flows
- **New external integrations**: Third-party API connections, webhook handlers, message queue producers/consumers
- **Infrastructure changes**: CI/CD pipeline modifications, deployment configs, Docker/K8s changes, new service definitions
- **New complex database queries**: Query optimization requiring model relationship changes, new scopes with joins across multiple tables, N+1 fixes that require adding/changing model associations
- **Multi-service changes**: Changes spanning multiple microservices, cross-repo modifications

**IMPORTANT — Avoid false positives**: Evaluate the _nature of the change_, not keywords in the description. Examples:
- "Add a red border to the login button" → SUITABLE (cosmetic change, "login" is just a location)
- "Sort the users table by name" → SUITABLE (simple ORDER BY, no relationship changes)
- "Change the footer to show a config value" → SUITABLE (reading an existing config, not adding infrastructure)
- "Add a new login method via OAuth" → NOT SUITABLE (new authentication flow)

**When refusing**, display a clear table:

```markdown
## Not suitable for `/speckit.quick`

| Detected | Category | Why |
|----------|----------|-----|
| [what was detected] | [category] | [brief explanation] |

This change involves [category] which requires the full specification pipeline
for proper planning, risk assessment, and implementation tracking.

**Use instead**: `/speckit.specify [description]` → `/speckit.plan` → `/speckit.tasks` → `/speckit.implement`
```

Then **STOP**. Do not proceed. Do not offer to continue. Do not ask the user if they want to proceed anyway.

**If borderline on the soft criteria** (estimated 11-15 files or 11-15 tasks, but NOT in a hard-refusal category):
Use **AskUserQuestion**:
- **"Proceed with quick"** (Recommended): Continue despite borderline complexity
- **"Switch to full pipeline"**: Abort and suggest `/speckit.specify`

**If estimated above 15 files or above 15 tasks**: Refuse outright (not borderline — too large for quick mode). Display the same refusal table format as hard refusals and redirect to the full pipeline.

---

## Step 3: Branch Setup

**Skip this step entirely** if the user chose "Use existing branch" in Step 1.

**STRICT RULE — Ask user for the branch name**:

1. Generate a suggested branch name (2-4 words, lowercase, hyphen-separated):
   - Use action-noun format when possible (e.g., "fix-button-color", "add-tooltip-settings")
   - Also generate one alternative variation (shorter or longer)
   - Branch prefixes (`feature/`, `fix/`, `tech/`, etc.) are supported

2. **You MUST use the `AskUserQuestion` tool** to ask the user which branch name to use. This step is **non-negotiable** — never skip it, never auto-select.
   - **Option 1** (Recommended): The primary suggested name
   - **Option 2**: An alternative variation
   - The user can always pick "Other" to type a custom name

3. Once the user responds, create the feature branch and spec directory:

   ```bash
   .specify/scripts/bash/create-new-feature.sh --json --branch-name "<chosen-name>" "<feature description>"
   ```

   - Parse JSON output for `BRANCH_NAME` and `SPEC_FILE`
   - Note: this also copies the full spec template to spec.md — we will overwrite it with minimal content in Step 5
   - **If the script fails** (git errors, branch name conflict, etc.): Report the error to the user and stop. Do not proceed without a valid branch and specs directory.

**IMPORTANT**: Only run `create-new-feature.sh` once per feature.

---

## Step 4: Codebase Analysis

Before generating artifacts, analyze the codebase to produce an accurate plan:

1. **Search for relevant files**: Use Glob and Grep to find files related to the change description. Identify:
   - Files that will need modification
   - Files that provide context (imports, dependencies, patterns)
   - Existing test files related to the change area

2. **Read key files**: Read the files that will be modified to understand:
   - Current code structure and patterns
   - Naming conventions
   - Import patterns
   - Testing patterns (if tests exist nearby)

3. **Build the change map**: Create an internal list of:
   - Files to modify (with specific changes needed)
   - Files to create (if any)
   - Dependencies between changes

4. **Stage 2: Post-analysis suitability re-check (HARD GATE)**

   After reading the actual code, re-evaluate whether this change truly qualifies for quick mode. The codebase analysis may reveal complexity that was not apparent from the description alone. Stage 1 screens based on the description; Stage 2 catches what only code inspection reveals.

   **You MUST refuse and STOP if the codebase analysis reveals ANY of the following:**

   These re-confirm Stage 1 categories after seeing the actual code:
   - The change requires **database schema modifications** (migrations, new columns, new tables, index changes)
   - The change requires **new or modified API endpoints** (new routes, controller actions, serializers)
   - The change involves **business logic** (workflow rules, state transitions, validation logic beyond simple format checks, pricing/billing calculations, permission/authorization rules)
   - The change touches **authentication or session handling** code
   - The change requires modifications to **CI/CD, deployment, or infrastructure** configs
   - The change introduces **new third-party service calls** or webhook handlers

   These are NEW checks only possible after reading the code (not detectable from description):
   - The change requires **new model associations** or relationship changes between existing models
   - The change requires **new background jobs, workers, or queue consumers**
   - The change involves **data transformations or backfills** on existing records
   - The affected files exceed **10 files** after actual count (not estimate)

   **When refusing after codebase analysis**, display:

   ```markdown
   ## Codebase analysis: too complex for `/speckit.quick`

   | Finding | Detail |
   |---------|--------|
   | [what was found in the code] | [specific files/lines that indicate complexity] |

   The description sounded simple, but codebase analysis reveals this change
   involves [category] which requires proper specification and planning.

   **Use instead**: `/speckit.specify [description]` → `/speckit.plan` → `/speckit.tasks` → `/speckit.implement`
   ```

   Then **STOP**. Do not proceed. Do not offer to continue. Do not ask the user if they want to proceed anyway.

   **Note about the branch**: The branch and specs directory were already created in Step 3. Inform the user:
   - They can continue with the full pipeline on this branch: `/speckit.specify` (to enrich spec.md) → `/speckit.plan` → `/speckit.tasks` → `/speckit.implement`
   - Or they can delete the branch if they want to abandon the change: `git checkout main && git branch -d <branch-name>`

---

## Step 4b: Load Project Memory

**Load project memory**: Always read `.specify/memory/constitution.md` if it exists. Then read `.specify/memory/index.md` and, if it lists files, read each listed file to gather project context (domain knowledge, tech decisions, conventions, lessons learned). Use this context to inform your work in the following steps. If `index.md` is missing or empty, skip silently.

---

## Step 5: Generate Minimal Artifacts

Generate THREE separate files at standard paths. All three are generated in ONE pass from the feature description + codebase analysis.

**CRITICAL**: Use separate `spec.md`, `plan.md`, and `tasks.md` files (NOT a combined file). This preserves compatibility with all existing speckit commands (`/speckit.status`, `/speckit.implement`, `/speckit.analyze`).

**Overwrite warning**: Before writing, check if `plan.md` or `tasks.md` already exist in FEATURE_DIR (they may exist from a previous full-pipeline run). If they do, warn the user that quick mode will overwrite them with minimal versions, and include this in the Step 6 confirmation display. The spec.md from `create-new-feature.sh` is always overwritten (expected behavior).

### 5a. Write minimal `spec.md`

Overwrite the spec template (created by `create-new-feature.sh`) with minimal content at `FEATURE_DIR/spec.md`:

```markdown
# Feature Specification: [FEATURE NAME]

**Feature Branch**: `[branch-name]`
**Created**: [DATE]
**Status**: Draft
**Mode**: Quick

## User Scenarios & Testing

### User Story 1 - [Brief Title] (Priority: P1)

[1-3 sentences describing the change and its purpose]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]
2. [Additional scenarios as needed]

## Requirements

### Functional Requirements

- **FR-001**: [requirement]
- **FR-002**: [requirement]
[Add more as needed, keep concise]

## Success Criteria

### Measurable Outcomes

- **SC-001**: [measurable outcome]
```

Keep this under 40 lines. Focus on WHAT changes, not HOW.

### 5b. Write minimal `plan.md`

Write directly to `FEATURE_DIR/plan.md` (do NOT use `setup-plan.sh` — it copies the full 106-line template):

```markdown
# Implementation Plan: [FEATURE NAME]

**Branch**: `[branch-name]` | **Date**: [DATE]
**Mode**: Quick

## Summary

[1-3 sentences: what we're changing and the technical approach]

## Technical Context

**Language/Framework**: [detected from codebase]
**Key Dependencies**: [relevant libraries/modules]
**Testing**: [detected test framework, or "manual verification"]

## Approach & Rationale

[Why this approach. Key decisions. Keep brief — 2-5 sentences max.]

## Affected Files

- `path/to/file1.ext` — [what changes]
- `path/to/file2.ext` — [what changes]
[List all files from the change map]

## Risks

- [Any risks or edge cases, or "None identified" for trivial changes]
```

Keep this under 40 lines. The `## Affected Files` section must list exact file paths from the codebase analysis.

### 5c. Write minimal `tasks.md`

Write to `FEATURE_DIR/tasks.md`:

```markdown
# Tasks: [FEATURE NAME]

**Input**: Design documents from `specs/[feature-dir]/`

## Tasks

- [ ] T001 [description with exact file path]
- [ ] T002 [description with exact file path]
- [ ] T003 [P] [description with exact file path]
[Add tasks as needed]

## Dependencies

[Simple dependency description, e.g.:]
T001 → T002 (sequential)
T003 independent / can run in parallel
```

Task format rules:
- Every task starts with `- [ ]` (markdown checkbox)
- Sequential task ID: T001, T002, T003...
- `[P]` marker only if task is parallelizable (different files, no dependencies)
- NO `[US1]` story labels (single implicit story in quick mode)
- Each task must include the exact file path
- Keep under 30 lines for the entire file

---

## Step 6: Show Plan & Get Confirmation

Present a formatted summary to the user, rendered from the generated artifacts:

```markdown
## Quick Change Plan: [branch-name]

### Summary
[1-2 sentence summary from plan.md]

### Files to modify/create
- `path/to/file1.ext` (modify: [reason])
- `path/to/file2.ext` (create: [reason])

### Tasks ([N] total)
- [ ] T001 [description]
- [ ] T002 [description]
...

### Scope: [N] files | [N] tasks | Complexity: Low/Medium
```

Then use **AskUserQuestion** with 3 options:

- **"Implement now" (Recommended)**: Proceed with implementation
- **"Edit plan first"**: Let the user modify the artifacts manually, then re-run `/speckit.quick` to resume
- **"Switch to full pipeline"**: Abort quick mode. Suggest the user enrich the generated spec.md and run `/speckit.plan` to continue with the full pipeline

**If user chooses "Edit plan first"**: Report artifact paths and stop. The user can edit the artifacts and then re-run `/speckit.quick` on the same branch to resume (it will detect existing specs and offer "Use existing branch"). Note: do NOT suggest running `/speckit.implement` — the quick-mode tasks.md uses a flat format without phases or `[US]` story labels, which is incompatible with what `/speckit.implement` expects. Similarly, do NOT suggest `/speckit.clarify` — the quick-mode spec.md has a minimal structure that differs from the full spec template `/speckit.clarify` expects.

**If user chooses "Switch to full pipeline"**: Report that minimal artifacts are already in place at standard paths. The user should:
1. Optionally run `/speckit.clarify` to enrich the spec (but must first run `/speckit.specify` to regenerate spec.md in the full template format — the quick-mode spec.md is not compatible with `/speckit.clarify`)
2. Run `/speckit.plan` to overwrite plan.md with the full template
3. Run `/speckit.tasks` to regenerate tasks.md in the full phase-based format
4. Run `/speckit.implement`
Note: The quick-mode worklog (if already created) uses `## Quick Implementation` headings instead of the `## Phase N:` format that `/speckit.implement` expects. If switching to the full pipeline, delete `worklog.md` so `/speckit.implement` creates a fresh one.

**If user chooses "Implement now"**: Proceed to Step 7.

---

## Step 7: Initialize Worklog

**STRICT RULE — You MUST create and maintain a worklog. This is non-negotiable.**

1. Copy `.specify/templates/worklog-template.md` to `FEATURE_DIR/worklog.md`
2. Replace `[FEATURE NAME]` with the feature name
3. Replace `[feature-name]` with the current branch name
4. Replace `[DATE]` with today's date

If `FEATURE_DIR/worklog.md` already exists (resuming): read it and continue appending.

---

## Step 8: Execute Implementation

**Pre-flight check**: Before executing, re-read `tasks.md` from disk to ensure it reflects the latest state (the user may have edited it after Step 6 confirmation). If the tasks differ from what was presented in Step 6, briefly note the differences and proceed with the on-disk version.

Execute tasks from `tasks.md` following these rules:

1. **Sequential execution**: Execute tasks in order, respecting dependencies
2. **Parallel tasks `[P]`**: May be executed together if they touch different files
3. **Mark completed tasks**: After completing each task, update `tasks.md` to mark it as `- [X]`
4. **Report progress**: After each task, briefly report what was done
5. **Halt on failure**: If a task fails, stop execution, report the error with context, and suggest next steps
6. **No phase structure**: Tasks are flat — no Setup/Foundational/Polish phases
7. **No checklist validation**: Skip checklist checks (quick mode has no checklists)
8. **No Project Setup Verification**: Skip ignore-file creation (quick mode operates on existing projects)

### Worklog Updates During Execution

**STRICT RULE — Update worklog after completing tasks.**

Since quick mode has no phases, update the worklog in logical groups (every 3-5 tasks, or after all tasks if fewer than 5):

```markdown
## Quick Implementation

### Tasks T001-T00N
{What was done, problems encountered, solutions applied}

### Summary
{Brief summary of this group's outcomes}
```

**Append** each entry to `FEATURE_DIR/worklog.md`. Never skip worklog updates.

---

## Step 9: Completion

After all tasks are executed:

1. **Write final worklog summary**: Append to `FEATURE_DIR/worklog.md`:

   ```markdown
   ## Summary of implementation of feature

   **Completed**: [DATE]
   **Status**: Complete

   ### Key accomplishments
   - [What was done]

   ### Files modified/created
   - `path/to/file1.ext`
   - `path/to/file2.ext`

   ### Challenges
   - [Any issues encountered and how they were resolved, or "None"]

   ### Deviations from plan
   - [Any changes from the original plan, or "None"]
   ```

2. **Update project memory**: If this session produced reusable project knowledge (patterns discovered, conventions, lessons learned), write or update the relevant file in `.specify/memory/` and update `.specify/memory/index.md` with the file entry. Keep memory files concise and project-scoped (not feature-specific). If no new reusable knowledge was produced, skip silently.

3. **Report completion** to the user:

   ```markdown
   ## Quick Change Complete: [branch-name]

   ### Summary
   [1-2 sentences]

   ### Completed Tasks
   - [X] T001 [description]
   - [X] T002 [description]
   ...

   ### Files Modified/Created
   - `path/to/file1.ext`
   - `path/to/file2.ext`

   ### Next Steps
   - Run tests if applicable
   - Review changes: `git diff`
   - Create a commit
   - Check status: `/speckit.status`
   ```

---

## Behavior Rules

- **Never skip the branch name AskUserQuestion** — this is a strict rule inherited from `/speckit.specify`
- **Never skip worklog creation and updates** — always initialize and maintain `worklog.md`
- **Always use separate files** (spec.md, plan.md, tasks.md) — never combine into a single file
- **Always confirm before implementing** — the Step 6 AskUserQuestion is mandatory
- **Always mark completed tasks** as `[X]` in tasks.md
- **If the change grows beyond quick scope** during implementation (e.g., discovering unexpected complexity), halt and suggest switching to the full pipeline
- **Respect user early termination** signals ("stop", "done", "cancel")
- If `$ARGUMENTS` is empty, display usage help and stop
