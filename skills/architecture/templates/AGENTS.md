# AI Agent Instructions

## Repository Structure

This repository uses a hybrid approach:

- **Query structured data:** `registry/*.yaml`
- **Read human context:** `domains/`, `services/`
- **Find contracts:** `contracts/`
- **Validate schemas:** `schemas/`

## Quick Queries

### "What services are in domain X?"

```text
registry/domains.yaml -> find by id -> services[]
```

### "What does service X consume?"

```text
registry/dependencies.yaml -> graph.{service}.consumes[]
```

### "What breaks if service X fails?"

```text
registry/dependencies.yaml -> search produces.to containing X
```

### "What is the schema for message X?"

```text
contracts/rabbitmq/{exchange}.md -> routing key -> schema link
OR registry/dependencies.yaml -> produces.schema
```

### "Who can write to Redis key X?"

```text
contracts/state/{entity}.md -> Access Matrix
```

### "What is the status of technology X?"

```text
registry/tech-radar.yaml -> entries[] -> find by name -> ring
```

### "What technologies are deprecated (Hold)?"

```text
registry/tech-radar.yaml -> entries[] -> filter ring=hold -> list with sunset_at
```

### "What services use technology X?"

```text
registry/tech-radar.yaml -> entries[] -> find by id -> used_by[]
OR registry/services.yaml -> services[] -> filter technologies contains X
```

### "What technologies does service X use?"

```text
registry/services.yaml -> services[] -> find by id -> technologies[]
-> cross-reference with registry/tech-radar.yaml for status
```

## File Discovery

| Need | Primary Source | Fallback |
|------|----------------|----------|
| Domain overview | `domains/{name}.md` | - |
| Service details | `services/{name}.md` | - |
| Service dependencies | `registry/dependencies.yaml` | - |
| Technology status | `registry/tech-radar.yaml` | `docs/tech-radar.md` |
| Service technologies | `registry/services.yaml` -> technologies[] | `services/{name}.md` |
| Message contracts | `contracts/rabbitmq/{exchange}.md` | - |
| Message schemas | `schemas/messages/*.json` | - |
| State contracts | `contracts/state/{entity}.md` | - |
| Visual diagrams | `diagrams/` | - |

## ID Conventions

| Entity | Pattern | Example |
|--------|---------|---------|
| Domain | `DOM-{2-3 letters}` | DOM-CC |
| Service | `SVC-{NAME}` | SVC-AGENTS |
| Technology | `TECH-{NAME}` | TECH-RUBY-3 |
| Role | `ROLE-{type}-{name}` | ROLE-SVC-AGENTS |

## Navigation Tips

1. Start with `registry/domains.yaml` to understand structure
2. Use `registry/dependencies.yaml` for impact analysis
3. Follow links from registry to detailed docs
4. Contracts are in `contracts/`, not embedded in services
