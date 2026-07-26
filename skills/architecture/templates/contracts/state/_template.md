# {Entity} State

> **Owner:** SVC-XX | **Storage:** {redis|postgres|clickhouse|mongodb}

## Storage Schema

<!-- Select ONE storage type and remove others -->

### Redis

| Pattern | Type | TTL | Description |
|---------|------|-----|-------------|
| `{entity}::{id}` | hash | none | Primary state |

**Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `state` | string | Current state |
| `updated_at` | string | ISO timestamp |
| `data` | json | Additional data |

### PostgreSQL

```sql
CREATE TABLE {table_name} (
  id UUID PRIMARY KEY,
  state VARCHAR(50) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  data JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_{table_name}_state ON {table_name}(state);
```

### ClickHouse

```sql
CREATE TABLE {table_name} (
  id String,
  state String,
  updated_at DateTime64(3),
  data String,
  event_date Date DEFAULT toDate(updated_at)
) ENGINE = ReplacingMergeTree(updated_at)
PARTITION BY toYYYYMM(event_date)
ORDER BY id;
```

### MongoDB

```javascript
// Collection: {collection_name}
{
  _id: ObjectId,
  state: String,
  updated_at: ISODate,
  data: Object
}
// Index: { state: 1 }
```

## Access Matrix

| Service | Read | Write | Notes |
|---------|------|-------|-------|
| SVC-XX | yes | yes | Owner |
| SVC-YY | yes | no | Consumer |

## Queries

| Query | Description | Frequency |
|-------|-------------|-----------|
| Get by ID | Fetch single record | High |
| List by state | Filter by state | Medium |
