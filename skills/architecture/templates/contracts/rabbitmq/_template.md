# Exchange: {exchange_name}

> **Type:** topic | **Durable:** true | **Owner:** {producing service}
> **Primary Owner:** SVC-XX (team-name)
> **Co-Producers:** SVC-YY, SVC-ZZ (if applicable)

## Routing Keys

### {routing.key}

| Field | Value |
|-------|-------|
| **Publisher** | [SVC-XX](../../services/xx.md) |
| **Consumers** | SVC-YY, SVC-ZZ |
| **Schema** | [{message}.v1.json](../../schemas/messages/{message}.v1.json) |
| **Versions** | v1 (current) |

**Payload:**

```json
{
  "id": 123,
  "type": "example",
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### {another.routing.key}

| Field | Value |
|-------|-------|
| **Publisher** | [SVC-YY](../../services/yy.md) |
| **Consumers** | SVC-XX |
| **Schema** | [{other-message}.v1.json](../../schemas/messages/{other-message}.v1.json) |

---

## Consumer Queues

| Queue | Service | Bindings | Prefetch |
|-------|---------|----------|----------|
| `{queue-name}` | SVC-XX | `{routing}.*` | 10 |
| `{other-queue}` | SVC-YY | `{routing}.state` | 50 |

## Versioning

| Version | Status | Routing Key | Schema | Sunset |
|---------|--------|-------------|--------|--------|
| v1 | current | `{routing.key}` | {message}.v1.json | - |
