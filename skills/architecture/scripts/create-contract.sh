#!/usr/bin/env bash
# Create a new contract artifact
#
# Usage:
#   ./scripts/create-contract.sh <type> <name> [options]
#
# Types: rabbitmq, http, state
#
# Options:
#   --owner SVC-XX        Service owner (default: SVC-XX)
#   --storage-type TYPE   For state contracts: redis|postgres|clickhouse|mongodb (default: redis)
#   --arch-dir PATH       Architecture directory path
#
# Examples:
#   ./scripts/create-contract.sh rabbitmq callcenter-topic --owner SVC-AGENTS
#   ./scripts/create-contract.sh state agent-state --owner SVC-AGENTS --storage-type redis
#   ./scripts/create-contract.sh state user-sessions --owner SVC-AUTH --storage-type postgres
#   ./scripts/create-contract.sh state metrics --owner SVC-ANALYTICS --storage-type clickhouse
#   ./scripts/create-contract.sh http public-v1 --owner SVC-WEB

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

show_help() {
    cat << EOF
Usage: $(basename "$0") <type> <name> [OPTIONS]

Create a new contract artifact.

Arguments:
  type          Contract type: rabbitmq, http, state
  name          Contract name (e.g., callcenter-topic, user-sessions)

Options:
  --owner SVC-XX          Service owner (default: SVC-XX)
  --storage-type TYPE     For state: any type (redis, postgres, clickhouse, mongodb, elasticsearch, etc.)
  --arch-dir PATH         Architecture directory path
  -h, --help              Show this help message

Examples:
  $(basename "$0") rabbitmq callcenter-topic --owner SVC-AGENTS
  $(basename "$0") state user-sessions --owner SVC-AUTH --storage-type postgres
  $(basename "$0") state metrics --owner SVC-ANALYTICS --storage-type clickhouse
  $(basename "$0") state search-index --owner SVC-SEARCH --storage-type elasticsearch
  $(basename "$0") http public-v1 --owner SVC-WEB
EOF
    exit 0
}

# Parse arguments
CONTRACT_TYPE=""
CONTRACT_NAME=""
OWNER="SVC-XX"
STORAGE_TYPE="redis"
ARCH_DIR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        --owner)
            OWNER="$2"
            shift 2
            ;;
        --storage-type)
            STORAGE_TYPE="$2"
            shift 2
            ;;
        --arch-dir)
            ARCH_DIR="$2"
            shift 2
            ;;
        -*)
            echo "Unknown option: $1"
            exit 1
            ;;
        *)
            if [[ -z "$CONTRACT_TYPE" ]]; then
                CONTRACT_TYPE="$1"
            else
                CONTRACT_NAME="$1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$CONTRACT_TYPE" ]] || [[ -z "$CONTRACT_NAME" ]]; then
    echo "Usage: $0 <type> <name> [--owner SVC-XX] [--storage-type TYPE] [--arch-dir path]"
    echo "Types: rabbitmq, http, state"
    echo "Storage types (for state): redis, postgres, clickhouse, mongodb"
    exit 1
fi

# Find architecture directory
if [[ -z "$ARCH_DIR" ]]; then
    GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
    ARCH_DIR="$GIT_ROOT/.architecture"
fi

if [[ ! -d "$ARCH_DIR" ]]; then
    echo -e "${RED}Error: Architecture directory not found: $ARCH_DIR${NC}"
    exit 1
fi

case "$CONTRACT_TYPE" in
    rabbitmq)
        CONTRACT_FILE="$ARCH_DIR/contracts/rabbitmq/${CONTRACT_NAME}.md"
        if [[ -f "$CONTRACT_FILE" ]]; then
            echo -e "${RED}Error: Contract file already exists: $CONTRACT_FILE${NC}"
            exit 1
        fi
        EXCHANGE_NAME=$(echo "$CONTRACT_NAME" | tr '-' '_')
        OWNER_LOWER=$(echo "$OWNER" | tr '[:upper:]' '[:lower:]' | sed 's/svc-//')
        cat > "$CONTRACT_FILE" << EOF
# Exchange: ${EXCHANGE_NAME}

> **Type:** topic | **Durable:** true | **Owner:** ${OWNER}
> **Primary Owner:** ${OWNER} (team-name)

## Routing Keys

### example.event

| Field | Value |
|-------|-------|
| **Publisher** | [${OWNER}](../../services/${OWNER_LOWER}.md) |
| **Consumers** | SVC-XX |
| **Schema** | [example-event.v1.json](../../schemas/messages/example-event.v1.json) |
| **Versions** | v1 (current) |

**Payload:**

\`\`\`json
{
  "id": 123,
  "type": "example",
  "timestamp": "2025-01-15T10:30:00Z"
}
\`\`\`

---

## Consumer Queues

| Queue | Service | Bindings | Prefetch |
|-------|---------|----------|----------|
| \`${CONTRACT_NAME}-queue\` | SVC-XX | \`example.*\` | 10 |

## Versioning

| Version | Status | Routing Key | Schema | Sunset |
|---------|--------|-------------|--------|--------|
| v1 | current | \`example.event\` | example-event.v1.json | - |
EOF
        ;;

    http)
        CONTRACT_FILE="$ARCH_DIR/contracts/http/${CONTRACT_NAME}.md"
        if [[ -f "$CONTRACT_FILE" ]]; then
            echo -e "${RED}Error: Contract file already exists: $CONTRACT_FILE${NC}"
            exit 1
        fi
        cat > "$CONTRACT_FILE" << EOF
# HTTP API: ${CONTRACT_NAME}

> **Owner:** ${OWNER} | **Base Path:** /api/v1 | **Auth:** api_key

## Endpoints

### GET /examples

| Field | Value |
|-------|-------|
| **Consumers** | external |
| **Auth** | api_key |
| **Response Schema** | [examples-response.json](../../schemas/api/examples-response.json) |

**Request:**

\`\`\`
GET /api/v1/examples?limit=10
Authorization: Bearer {api_key}
\`\`\`

**Response:**

\`\`\`json
{
  "data": [
    {"id": 1, "name": "Example"}
  ],
  "meta": {
    "total": 100,
    "page": 1
  }
}
\`\`\`

## Error Responses

| Code | Description |
|------|-------------|
| 400 | Bad Request - Invalid input |
| 401 | Unauthorized - Invalid or missing auth |
| 404 | Not Found - Resource doesn't exist |
| 500 | Internal Server Error |
EOF
        ;;

    state)
        CONTRACT_FILE="$ARCH_DIR/contracts/state/${CONTRACT_NAME}.md"
        if [[ -f "$CONTRACT_FILE" ]]; then
            echo -e "${RED}Error: Contract file already exists: $CONTRACT_FILE${NC}"
            exit 1
        fi

        ENTITY_NAME=$(echo "$CONTRACT_NAME" | tr '-' '_')
        TABLE_NAME="${ENTITY_NAME}"

        # Note: Any storage type is allowed; known types get specialized templates
        # Capitalize first letter for display (macOS compatible)
        STORAGE_DISPLAY="$(echo "$STORAGE_TYPE" | cut -c1 | tr '[:lower:]' '[:upper:]')$(echo "$STORAGE_TYPE" | cut -c2-)"

        # Generate storage-specific content
        case "$STORAGE_TYPE" in
            redis)
                cat > "$CONTRACT_FILE" << EOF
# ${CONTRACT_NAME} State

> **Owner:** ${OWNER} | **Storage:** Redis

## Key Patterns

| Pattern | Type | TTL | Description |
|---------|------|-----|-------------|
| \`${ENTITY_NAME}::{id}\` | hash | none | Primary state |
| \`${ENTITY_NAME}_index\` | set | none | ID index |

## Schema: \`${ENTITY_NAME}::{id}\`

| Field | Type | Description |
|-------|------|-------------|
| \`state\` | string | Current state |
| \`updated_at\` | string | ISO timestamp |
| \`data\` | json | Additional data |

## Access Matrix

| Service | Read | Write | Notes |
|---------|------|-------|-------|
| ${OWNER} | yes | yes | Owner |
| SVC-XX | yes | no | Consumer |

## Queries

| Operation | Command | Frequency |
|-----------|---------|-----------|
| Get by ID | \`HGETALL ${ENTITY_NAME}::{id}\` | High |
| Set field | \`HSET ${ENTITY_NAME}::{id} field value\` | Medium |
| Get all IDs | \`SMEMBERS ${ENTITY_NAME}_index\` | Low |
EOF
                ;;

            postgres)
                cat > "$CONTRACT_FILE" << EOF
# ${CONTRACT_NAME} State

> **Owner:** ${OWNER} | **Storage:** PostgreSQL

## Table Schema

\`\`\`sql
CREATE TABLE ${TABLE_NAME} (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  state VARCHAR(50) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  data JSONB
);

CREATE INDEX idx_${TABLE_NAME}_state ON ${TABLE_NAME}(state);
CREATE INDEX idx_${TABLE_NAME}_updated_at ON ${TABLE_NAME}(updated_at);
\`\`\`

## Columns

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| \`id\` | UUID | no | Primary key |
| \`state\` | VARCHAR(50) | no | Current state |
| \`updated_at\` | TIMESTAMPTZ | no | Last update |
| \`created_at\` | TIMESTAMPTZ | no | Creation time |
| \`data\` | JSONB | yes | Additional data |

## Access Matrix

| Service | Read | Write | Notes |
|---------|------|-------|-------|
| ${OWNER} | yes | yes | Owner |
| SVC-XX | yes | no | Consumer |

## Queries

| Query | Description | Frequency |
|-------|-------------|-----------|
| \`SELECT * FROM ${TABLE_NAME} WHERE id = ?\` | Get by ID | High |
| \`SELECT * FROM ${TABLE_NAME} WHERE state = ?\` | List by state | Medium |
| \`UPDATE ${TABLE_NAME} SET state = ?, updated_at = NOW() WHERE id = ?\` | Update state | Medium |
EOF
                ;;

            clickhouse)
                cat > "$CONTRACT_FILE" << EOF
# ${CONTRACT_NAME} State

> **Owner:** ${OWNER} | **Storage:** ClickHouse

## Table Schema

\`\`\`sql
CREATE TABLE ${TABLE_NAME} (
  id String,
  state String,
  updated_at DateTime64(3),
  created_at DateTime64(3) DEFAULT now64(3),
  data String,
  event_date Date DEFAULT toDate(updated_at)
) ENGINE = ReplacingMergeTree(updated_at)
PARTITION BY toYYYYMM(event_date)
ORDER BY id
SETTINGS index_granularity = 8192;
\`\`\`

## Columns

| Column | Type | Description |
|--------|------|-------------|
| \`id\` | String | Primary key |
| \`state\` | String | Current state |
| \`updated_at\` | DateTime64(3) | Last update (ms precision) |
| \`created_at\` | DateTime64(3) | Creation time |
| \`data\` | String | JSON data as string |
| \`event_date\` | Date | Partition key |

## Access Matrix

| Service | Read | Write | Notes |
|---------|------|-------|-------|
| ${OWNER} | yes | yes | Owner |
| SVC-XX | yes | no | Consumer |

## Queries

| Query | Description | Frequency |
|-------|-------------|-----------|
| \`SELECT * FROM ${TABLE_NAME} FINAL WHERE id = ?\` | Get by ID | High |
| \`SELECT * FROM ${TABLE_NAME} FINAL WHERE state = ?\` | List by state | Medium |
| \`SELECT count() FROM ${TABLE_NAME} FINAL GROUP BY state\` | State counts | Low |
EOF
                ;;

            mongodb)
                cat > "$CONTRACT_FILE" << EOF
# ${CONTRACT_NAME} State

> **Owner:** ${OWNER} | **Storage:** MongoDB

## Collection Schema

**Collection:** \`${TABLE_NAME}\`

\`\`\`javascript
{
  _id: ObjectId,
  state: String,           // Required
  updated_at: ISODate,     // Required
  created_at: ISODate,     // Required
  data: Object             // Optional, flexible schema
}
\`\`\`

## Indexes

\`\`\`javascript
db.${TABLE_NAME}.createIndex({ state: 1 })
db.${TABLE_NAME}.createIndex({ updated_at: -1 })
\`\`\`

## Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| \`_id\` | ObjectId | yes | Primary key |
| \`state\` | String | yes | Current state |
| \`updated_at\` | ISODate | yes | Last update |
| \`created_at\` | ISODate | yes | Creation time |
| \`data\` | Object | no | Additional data |

## Access Matrix

| Service | Read | Write | Notes |
|---------|------|-------|-------|
| ${OWNER} | yes | yes | Owner |
| SVC-XX | yes | no | Consumer |

## Queries

| Query | Description | Frequency |
|-------|-------------|-----------|
| \`db.${TABLE_NAME}.findOne({ _id: id })\` | Get by ID | High |
| \`db.${TABLE_NAME}.find({ state: state })\` | List by state | Medium |
| \`db.${TABLE_NAME}.updateOne({ _id: id }, { \$set: { state, updated_at } })\` | Update state | Medium |
EOF
                ;;

            *)
                # Generic template for any other storage type
                cat > "$CONTRACT_FILE" << EOF
# ${CONTRACT_NAME} State

> **Owner:** ${OWNER} | **Storage:** ${STORAGE_DISPLAY}

## Schema

Describe the schema for ${STORAGE_TYPE} storage.

\`\`\`
# Add ${STORAGE_TYPE}-specific schema here
\`\`\`

## Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| \`id\` | string | yes | Primary key |
| \`state\` | string | yes | Current state |
| \`updated_at\` | timestamp | yes | Last update |
| \`created_at\` | timestamp | yes | Creation time |
| \`data\` | object | no | Additional data |

## Access Matrix

| Service | Read | Write | Notes |
|---------|------|-------|-------|
| ${OWNER} | yes | yes | Owner |
| SVC-XX | yes | no | Consumer |

## Queries

| Query | Description | Frequency |
|-------|-------------|-----------|
| Get by ID | Retrieve single record | High |
| List by state | Filter by state field | Medium |
| Update state | Modify state field | Medium |
EOF
                ;;
        esac
        ;;

    *)
        echo -e "${RED}Error: Unknown contract type: $CONTRACT_TYPE${NC}"
        echo "Types: rabbitmq, http, state"
        exit 1
        ;;
esac

echo -e "${GREEN}Created contract: $CONTRACT_FILE${NC}"
echo ""
echo "Next steps:"
echo "  1. Update $CONTRACT_FILE with actual contract details"
echo "  2. Create JSON schema in schemas/ if needed"
echo "  3. Run ./scripts/validate.sh to verify"
