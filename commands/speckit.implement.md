---
description: Execute the implementation plan by processing and executing all tasks defined in tasks.md
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. Run `.specify/scripts/bash/check-prerequisites.sh --json --require-spec --require-plan --require-tasks --include-tasks` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Check checklists status** (if FEATURE_DIR/checklists/ exists):
   - Scan all checklist files in the checklists/ directory
   - For each checklist, count:
     - Total items: All lines matching `- [ ]` or `- [X]` or `- [x]`
     - Completed items: Lines matching `- [X]` or `- [x]`
     - Incomplete items: Lines matching `- [ ]`
   - Create a status table:

     ```text
     | Checklist | Total | Completed | Incomplete | Status |
     |-----------|-------|-----------|------------|--------|
     | ux.md     | 12    | 12        | 0          | ✓ PASS |
     | test.md   | 8     | 5         | 3          | ✗ FAIL |
     | security.md | 6   | 6         | 0          | ✓ PASS |
     ```

   - Calculate overall status:
     - **PASS**: All checklists have 0 incomplete items
     - **FAIL**: One or more checklists have incomplete items

   - **If any checklist is incomplete**:
     - Display the table with incomplete item counts
     - **STOP** and ask: "Some checklists are incomplete. Do you want to proceed with implementation anyway? (yes/no)"
     - Wait for user response before continuing
     - If user says "no" or "wait" or "stop", halt execution
     - If user says "yes" or "proceed" or "continue", proceed to step 3

   - **If all checklists are complete**:
     - Display the table showing all checklists passed
     - Automatically proceed to step 3

3. Load and analyze the implementation context:
   - **REQUIRED**: Read tasks.md for the complete task list and execution plan
   - **REQUIRED**: Read plan.md for tech stack, architecture, and file structure
   - **IF EXISTS**: Read data-model.md for entities and relationships
   - **IF EXISTS**: Read contracts/ for API specifications and test requirements
   - **IF EXISTS**: Read research.md for technical decisions and constraints
   - **IF EXISTS**: Read quickstart.md for integration scenarios
   - **Load project memory**: Always read `.specify/memory/constitution.md` if it exists. Then read `.specify/memory/index.md` and, if it lists files, read each listed file to gather project context (domain knowledge, tech decisions, conventions, lessons learned). Use this context to inform your work. If `index.md` is missing or empty, skip silently.

4. **STRICT RULE — Initialize and maintain worklog**:

   **You MUST create and update a worklog file throughout implementation. This is non-negotiable — never skip worklog updates.**

   - If `FEATURE_DIR/worklog.md` does not exist:
     - Copy `.specify/templates/worklog-template.md` to `FEATURE_DIR/worklog.md`
     - Replace `[FEATURE NAME]` with the feature name from plan.md
     - Replace `[feature-name]` with the current branch name
     - Replace `[DATE]` with today's date
   - If `FEATURE_DIR/worklog.md` already exists (resuming implementation):
     - Read it and continue appending from where it left off

   **Worklog update rules** (enforced in steps 7 and 10):
   - After completing **every phase**, immediately append a phase entry to worklog.md
   - Each phase entry MUST include: tasks covered, what was done, problems encountered, solutions applied, and a phase summary
   - After **all phases complete**, append the final `## Summary of implementation of feature` section
   - **NEVER proceed to the next phase without updating the worklog first**
   - **NEVER skip the final summary**

   **Worklog entry format** (per phase):

   ```markdown
   ## Phase N: [Phase Name]

   ### Tasks [range or individual]
   {What was done, problems encountered, solutions applied}

   ### Summary
   {Brief summary of this phase's outcomes}
   ```

5. **Project Setup Verification**:
   - **REQUIRED**: Create/verify ignore files based on actual project setup:

   **Detection & Creation Logic**:
   - Check if the following command succeeds to determine if the repository is a git repo (create/verify .gitignore if so):

     ```sh
     git rev-parse --git-dir 2>/dev/null
     ```

   - Check if Dockerfile* exists or Docker in plan.md → create/verify .dockerignore
   - Check if .eslintrc* exists → create/verify .eslintignore
   - Check if eslint.config.* exists → ensure the config's `ignores` entries cover required patterns
   - Check if .prettierrc* exists → create/verify .prettierignore
   - Check if .npmrc or package.json exists → create/verify .npmignore (if publishing)
   - Check if terraform files (*.tf) exist → create/verify .terraformignore
   - Check if .helmignore needed (helm charts present) → create/verify .helmignore

   **If ignore file already exists**: Verify it contains essential patterns, append missing critical patterns only
   **If ignore file missing**: Create with full pattern set for detected technology

   **Common Patterns by Technology** (from plan.md tech stack):
   - **Node.js/JavaScript/TypeScript**: `node_modules/`, `dist/`, `build/`, `*.log`, `.env*`
   - **Python**: `__pycache__/`, `*.pyc`, `.venv/`, `venv/`, `dist/`, `*.egg-info/`
   - **Java**: `target/`, `*.class`, `*.jar`, `.gradle/`, `build/`
   - **C#/.NET**: `bin/`, `obj/`, `*.user`, `*.suo`, `packages/`
   - **Go**: `*.exe`, `*.test`, `vendor/`, `*.out`
   - **Ruby**: `.bundle/`, `log/`, `tmp/`, `*.gem`, `vendor/bundle/`
   - **PHP**: `vendor/`, `*.log`, `*.cache`, `*.env`
   - **Rust**: `target/`, `debug/`, `release/`, `*.rs.bk`, `*.rlib`, `*.prof*`, `.idea/`, `*.log`, `.env*`
   - **Kotlin**: `build/`, `out/`, `.gradle/`, `.idea/`, `*.class`, `*.jar`, `*.iml`, `*.log`, `.env*`
   - **C++**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.so`, `*.a`, `*.exe`, `*.dll`, `.idea/`, `*.log`, `.env*`
   - **C**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.a`, `*.so`, `*.exe`, `Makefile`, `config.log`, `.idea/`, `*.log`, `.env*`
   - **Swift**: `.build/`, `DerivedData/`, `*.swiftpm/`, `Packages/`
   - **R**: `.Rproj.user/`, `.Rhistory`, `.RData`, `.Ruserdata`, `*.Rproj`, `packrat/`, `renv/`
   - **Universal**: `.DS_Store`, `Thumbs.db`, `*.tmp`, `*.swp`, `.vscode/`, `.idea/`

   **Tool-Specific Patterns**:
   - **Docker**: `node_modules/`, `.git/`, `Dockerfile*`, `.dockerignore`, `*.log*`, `.env*`, `coverage/`
   - **ESLint**: `node_modules/`, `dist/`, `build/`, `coverage/`, `*.min.js`
   - **Prettier**: `node_modules/`, `dist/`, `build/`, `coverage/`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`
   - **Terraform**: `.terraform/`, `*.tfstate*`, `*.tfvars`, `.terraform.lock.hcl`
   - **Kubernetes/k8s**: `*.secret.yaml`, `secrets/`, `.kube/`, `kubeconfig*`, `*.key`, `*.crt`

6. Parse tasks.md structure and extract:
   - **Task phases**: Setup, Foundational, User Stories (one phase per story in priority order), Polish
   - **Task dependencies**: Sequential vs parallel execution rules
   - **Task details**: ID, description, file paths, parallel markers [P], story labels [US1] etc.
   - **Execution flow**: Order and dependency requirements

7. Execute implementation following the task plan:
   - **Phase-by-phase execution**: Complete each phase before moving to the next
   - **Respect dependencies**: Run sequential tasks in order, parallel tasks [P] can run together
   - **Test ordering**: If test tasks exist in a phase, execute them before their corresponding implementation tasks
   - **File-based coordination**: Tasks affecting the same files must run sequentially
   - **Validation checkpoints**: Verify each phase completion before proceeding
   - **STRICT RULE — Update worklog after EVERY phase**: After completing each phase, you MUST immediately append a worklog entry to `FEATURE_DIR/worklog.md` before proceeding to the next phase. This is non-negotiable — never skip, never defer, never batch multiple phases into one entry. Each entry MUST describe: tasks covered, what was accomplished, problems encountered, solutions applied, and a phase summary. **NEVER move to the next phase without writing the worklog entry first.**

8. Implementation execution rules (aligned with tasks.md phase schema):
   - **Phase 1 - Setup**: Initialize project structure, dependencies, configuration
   - **Phase 2 - Foundational**: Blocking prerequisites that must complete before user stories (shared models, middleware, base services)
   - **Phase 3+ - User Stories**: Execute each story's tasks in priority order. Within each story: Models → Services → Endpoints → Integration. If test tasks exist, run them before their corresponding implementation tasks
   - **Final Phase - Polish**: Cross-cutting concerns, documentation, performance optimization, final validation

9. Progress tracking and error handling:
   - Report progress after each completed task
   - Halt execution if any non-parallel task fails
   - For parallel tasks [P], continue with successful tasks, report failed ones
   - Provide clear error messages with context for debugging
   - Suggest next steps if implementation cannot proceed
   - **IMPORTANT** For completed tasks, make sure to mark the task off as [X] in the tasks file.

10. Completion validation:
   - Verify all required tasks are completed
   - Check that implemented features match the original specification
   - Validate that tests pass and coverage meets requirements
   - Confirm the implementation follows the technical plan
   - Report final status with summary of completed work
   - **Update project memory**: If this session produced reusable project knowledge (patterns discovered, lessons learned, conventions established), write or update the relevant file in `.specify/memory/` and update `.specify/memory/index.md` with the file entry. Keep memory files concise and project-scoped (not feature-specific). If no new reusable knowledge was produced, skip silently.
   - **STRICT RULE — Write final worklog summary**: Append the `## Summary of implementation of feature` section to `FEATURE_DIR/worklog.md` with an overall summary of the entire implementation covering: key accomplishments, major challenges and how they were resolved, deviations from the original plan, and final state of the feature. This is non-negotiable.

Note: This command assumes a complete task breakdown exists in tasks.md. If tasks are incomplete or missing, suggest running `/speckit.tasks` first to regenerate the task list.
