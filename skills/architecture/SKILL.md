---
name: architecture
description: Manage architecture documentation in .architecture directory. Use when Claude needs to (1) create/update/delete architecture artifacts (domains, services, contracts, schemas), (2) validate architecture documentation, (3) query service dependencies or technology status, (4) document new services or domains, (5) work with RabbitMQ/Redis/PostgreSQL/ClickHouse/MongoDB/HTTP contracts. Triggers on "architecture", "add service", "add domain", "document service", "create contract", "validate architecture".
---

# Architecture Documentation Skill

Manage architecture documentation using a hybrid approach: structured YAML registries for AI queries, Markdown for human context, and JSON Schema for validation.

## Quick Start

All scripts run from the **git root** directory (where `.git` is located):

```bash
# Initialize .architecture (run once from git root, using full path to skill)
/path/to/skills/architecture/scripts/init.sh

# After init, all scripts run from git root using .architecture/scripts/
.architecture/scripts/create-domain.sh contact-center --id DOM-CC --owner core-team
.architecture/scripts/create-service.sh agents --domain contact-center
.architecture/scripts/create-contract.sh rabbitmq callcenter-topic --owner SVC-AGENTS
.architecture/scripts/create-schema.sh message agent-state --version v2

# Validate
.architecture/scripts/validate.sh
```

## Commands

### /architecture init

Initialize `.architecture` directory in git root. The LIVE tree in this
repository looks like this (keep docs consistent with it):

```
.architecture/
├── AGENTS.md                 # AI navigation guide
├── CONTRIBUTING.md           # How to add/update docs
├── registry/                 # Machine-queryable YAML
│   ├── domains.yaml          # Domain definitions (authoritative)
│   ├── services.yaml         # Service metadata (authoritative)
│   ├── libraries.yaml        # Shared library registry (authoritative)
│   ├── deployments.yaml      # Compose deployment groups (authoritative)
│   ├── tech-radar.yaml       # Technology status (authoritative)
│   └── ...                   # generated: dependencies, exchanges, http-apis, state-keys
├── domains/                  # Domain documentation
├── services/                 # Service documentation
├── contracts/                # Contracts (rabbitmq, http, state)
├── deployments/              # Deployment group documentation (app1..., compliance)
├── diagrams/                 # Mermaid diagrams (L2/, L3/, flows/)
├── scratchpad/               # Working notes (lint-ignored)
├── scripts/                  # Create/generate/validate scripts
└── templates/                # Artifact templates (copied by init.sh)
```

Note: a fresh `init.sh` run additionally creates `schemas/`, `decisions/`,
and `docs/`. The live tree does not use them — no JSON schemas, ADRs, or
extra docs exist yet (git does not track the empty dirs). Treat them as
planned-but-unused; see the create-schema note below before using
`create-schema.sh`.

### /architecture create service \<name\>

Create service documentation with:
- `services/{name}.md` - Service documentation
- Registry entry template for `services.yaml`

Options: `--domain SLUG` (e.g., `contact-center`), `--domain-id DOM-XX` (optional), `--arch-dir path`

### /architecture create domain \<slug\>

Create domain documentation with:
- `domains/{slug}.md` - Domain documentation
- `diagrams/L2/{slug}.mmd` - Container diagram
- `diagrams/L3/{slug}.mmd` - Component diagram
- Registry entry template for `domains.yaml`

Options: `--id DOM-XX`, `--owner team`, `--arch-dir path`

### /architecture create contract \<type\> \<name\>

Create contract documentation. Types: `rabbitmq`, `http`, `state`

Options:
- `--owner SVC-XX` - Service owner
- `--storage-type TYPE` - For state contracts: any storage type (redis, postgres, clickhouse, mongodb, elasticsearch, etc.)
- `--arch-dir path` - Architecture directory path

Examples:
```bash
./scripts/create-contract.sh state user-sessions --owner SVC-AUTH --storage-type postgres
./scripts/create-contract.sh state metrics --owner SVC-ANALYTICS --storage-type clickhouse
./scripts/create-contract.sh state search-index --owner SVC-SEARCH --storage-type elasticsearch
```

### /architecture create schema \<type\> \<name\>

Create JSON Schema. Types: `message`, `api`

Options: `--version v1`, `--arch-dir path`

**Live-tree caveat**: the live `.architecture/` has no `schemas/`
directory and `create-schema.sh` does not create it. Before first use,
create it on demand:

```bash
mkdir -p .architecture/schemas/{messages,api}
```

No schemas exist in this repo yet; contracts in `contracts/` are the
canonical message documentation today.

### /architecture validate

Run all validators:
- `yamllint` - YAML syntax
- `markdownlint-cli2` - Markdown style
- `lint-mermaid.mjs` - Mermaid diagram syntax
- `validate-links.sh` - Cross-reference integrity (docs paths, domain IDs, tech IDs)

### /architecture generate

Regenerate registry files from contracts:

```bash
./scripts/generate-dependencies.sh  # Build dependency graph from contracts
./scripts/generate-exchanges.sh     # Index RabbitMQ exchanges
./scripts/generate-http-apis.sh     # Index HTTP APIs
./scripts/generate-state-keys.sh    # Index state storage keys/tables
```

## Registry Query Patterns

### Find services in domain

```yaml
# registry/domains.yaml
domains[].services[]  # e.g., [SVC-AGENTS, SVC-WEB]
```

### Find service dependencies

```yaml
# registry/dependencies.yaml
graph.{SVC-ID}.consumes[]   # What it consumes
graph.{SVC-ID}.produces[]   # What it produces
```

### Find technology status

```yaml
# registry/tech-radar.yaml
entries[].ring  # adopt | trial | assess | hold
```

### Find deprecated technologies

```yaml
# registry/tech-radar.yaml
entries[] | select(.ring == "hold")
```

### Find shared libraries and their consumers

```yaml
# registry/libraries.yaml
libraries[].id          # LIB-CC-LIB, LIB-AR-TYPEDSTORE, LIB-CC-TICKER,
                        # LIB-DESIGN-SYSTEM, LIB-LOCALIZATION, LIB-FRONTEND-LIBS
libraries[].used_by[]   # Consuming SVC-IDs
libraries[].docs        # Points into .specify/memory/ or repo READMEs
```

### Find services in a deployment group

```yaml
# registry/deployments.yaml
deployments[].id          # DEPLOY-APP1, DEPLOY-APP2, ...
deployments[].path        # docker/compose/<group>/
deployments[].images[]    # Images deployed in the group
deployments[].containers  # Container count
```

## Artifact Templates

Templates are in `templates/` directory:
- `registry/*.yaml` - Registry file templates
- `domains/_template.md` - Domain documentation
- `services/_template.md` - Service documentation
- `contracts/rabbitmq/_template.md` - RabbitMQ contract
- `contracts/http/_template.md` - HTTP API contract
- `contracts/state/_template.md` - State storage contract (Redis/PostgreSQL/ClickHouse/MongoDB)
- `schemas/messages/_template.v1.json` - Message schema
- `diagrams/L2/_template.mmd` - L2 container diagram
- `diagrams/L3/_template.mmd` - L3 component diagram

## Validation

Requires these tools:
- `yamllint` - `pip install yamllint`
- `markdownlint-cli2` - `npm install -g markdownlint-cli2`
- Node.js dependencies - `cd .architecture && npm install`

Configuration files:
- `.yamllint.yml` - YAML lint rules
- `.markdownlint-cli2.jsonc` - markdownlint-cli2 entry config (extends
  `.markdownlint.json`, disables MD060, ignores `node_modules/` and
  `scratchpad/`). `validate.sh` cd's into `.architecture/` so
  markdownlint-cli2 picks it up automatically.
- `.markdownlint.json` - base Markdown lint rules (referenced by the
  cli2 config; not passed directly)

## Subagent: Architecture Worker

For complex architecture tasks, spawn a dedicated subagent:

```
Task prompt: "Work on architecture documentation in .architecture directory.
Your role: Architecture documentation specialist.
Run all scripts from git root directory.

Available scripts (run from git root):
- .architecture/scripts/create-domain.sh - Create domain
- .architecture/scripts/create-service.sh - Create service
- .architecture/scripts/create-contract.sh - Create contract
- .architecture/scripts/create-schema.sh - Create schema
- .architecture/scripts/validate.sh - Validate all
- .architecture/scripts/generate-*.sh - Regenerate registry indexes

Registry files (YAML, queryable):
- .architecture/registry/domains.yaml - Domain definitions
- .architecture/registry/services.yaml - Service metadata
- .architecture/registry/libraries.yaml - Shared library registry
- .architecture/registry/deployments.yaml - Compose deployment groups
- .architecture/registry/tech-radar.yaml - Technology status
- .architecture/registry/dependencies.yaml - Dependency graph (generated)

Documentation (Markdown):
- .architecture/domains/{slug}.md - Domain context
- .architecture/services/{name}.md - Service details
- .architecture/contracts/{type}/{name}.md - Contracts
- .architecture/deployments/{group}.md - Deployment group details

Task: {specific task description}"
```

## ID Conventions

| Entity | Pattern | Example |
|--------|---------|---------|
| Domain | `DOM-{2-3 letters}` | `DOM-CC` |
| Service | `SVC-{NAME}` | `SVC-AGENTS`, `SVC-BILLING-API` |
| Technology | `TECH-{NAME}` | `TECH-RUBY-3`, `TECH-POSTGRES` |

All IDs use UPPERCASE with hyphens (not underscores) as separators.

## Source of Truth Hierarchy

```
CANONICAL (contracts/, schemas/)     <- Human-edited, primary source
         | generates
GENERATED (registry/dependencies.yaml, exchanges.yaml, etc.)
         | references
AUTHORITATIVE (registry/domains.yaml, services.yaml, tech-radar.yaml)
```

### Conflict Resolution Requirements

| ID | Requirement |
|----|-------------|
| REQ-ST-001 | If a conflict exists between a CANONICAL file and a GENERATED file, then the skill shall use the CANONICAL file as the source of truth. |
| REQ-ST-002 | If a conflict exists between a GENERATED file and an AUTHORITATIVE file, then the skill shall use the AUTHORITATIVE file as the source of truth. |
| REQ-ST-003 | When a CANONICAL file is modified, the skill shall regenerate dependent GENERATED files. |
