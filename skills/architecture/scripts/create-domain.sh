#!/usr/bin/env bash
# Create a new domain artifact
#
# Usage:
#   ./scripts/create-domain.sh <domain-slug> [--id DOM-XX] [--owner team] [--arch-dir path]
#
# Examples:
#   ./scripts/create-domain.sh contact-center --id DOM-CC --owner core-team
#   ./scripts/create-domain.sh my-domain

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

show_help() {
    cat << EOF
Usage: $(basename "$0") <domain-slug> [OPTIONS]

Create a new domain artifact with documentation and diagrams.

Arguments:
  domain-slug   Domain slug (e.g., contact-center, billing)

Options:
  --id DOM-XX       Domain ID (default: auto-generated from slug)
  --owner TEAM      Team owner (default: platform-team)
  --arch-dir PATH   Architecture directory path
  -h, --help        Show this help message

Creates:
  - domains/{slug}.md       Domain documentation
  - diagrams/L2/{slug}.mmd  Container diagram
  - diagrams/L3/{slug}.mmd  Component diagram

Examples:
  $(basename "$0") contact-center --id DOM-CC --owner core-team
  $(basename "$0") billing --owner finance-team
EOF
    exit 0
}

# Parse arguments
DOMAIN_SLUG=""
DOMAIN_ID=""
OWNER="platform-team"
ARCH_DIR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        --id)
            DOMAIN_ID="$2"
            shift 2
            ;;
        --owner)
            OWNER="$2"
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
            DOMAIN_SLUG="$1"
            shift
            ;;
    esac
done

if [[ -z "$DOMAIN_SLUG" ]]; then
    echo "Usage: $0 <domain-slug> [--id DOM-XX] [--owner team] [--arch-dir path]"
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

# Generate domain ID if not provided
if [[ -z "$DOMAIN_ID" ]]; then
    # Take first letters of each word, uppercase
    DOMAIN_ID="DOM-$(echo "$DOMAIN_SLUG" | tr '-' '\n' | cut -c1 | tr '[:lower:]' '[:upper:]' | tr -d '\n')"
fi

# Convert slug to title
DOMAIN_NAME=$(echo "$DOMAIN_SLUG" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')

DOMAIN_FILE="$ARCH_DIR/domains/${DOMAIN_SLUG}.md"
L2_DIAGRAM="$ARCH_DIR/diagrams/L2/${DOMAIN_SLUG}.mmd"
L3_DIAGRAM="$ARCH_DIR/diagrams/L3/${DOMAIN_SLUG}.mmd"

if [[ -f "$DOMAIN_FILE" ]]; then
    echo -e "${RED}Error: Domain file already exists: $DOMAIN_FILE${NC}"
    exit 1
fi

# Create domain documentation
cat > "$DOMAIN_FILE" << EOF
# ${DOMAIN_NAME}

> **ID:** ${DOMAIN_ID} | **Owner:** ${OWNER} | **Status:** active

## Purpose

{1-2 sentences: what business capability this domain provides}

## Boundaries

| Owns | Depends On |
|------|------------|
| {Aggregate/Concept} | [DOM-XX](./other.md) via {what} |

## Services

| Service | Responsibility | Status |
|---------|----------------|--------|
| [SVC-XX](../services/xx.md) | {one line} | active |

## Inter-Domain Contracts

| Direction | Domain | Exchange | Contract |
|-----------|--------|----------|----------|
| -> produces | DOM-XX | exchange_name | [routing.key](../contracts/rabbitmq/exchange.md#routingkey) |
| <- consumes | DOM-XX | exchange_name | [routing.*](../contracts/rabbitmq/exchange.md) |

## Diagrams

- [L2 Containers](../diagrams/L2/${DOMAIN_SLUG}.mmd)
- [L3 Components](../diagrams/L3/${DOMAIN_SLUG}.mmd)

## Key Invariants

1. {Business rule that must always hold}
2. {Another invariant}
EOF

# Create L2 diagram
cat > "$L2_DIAGRAM" << EOF
%% L2 Container Diagram: ${DOMAIN_NAME}
%% C4 Model Level 2 - Container view

graph TB
    subgraph domain["${DOMAIN_NAME}"]
        svc1["{Service 1}<br/>Ruby"]
    end

    subgraph data["Data Stores"]
        db[(PostgreSQL)]
        redis[(Redis)]
        rabbit{{RabbitMQ}}
    end

    svc1 --> db
    svc1 --> redis
    svc1 --> rabbit

    classDef service fill:#438DD5,stroke:#2E6295,color:#fff
    classDef database fill:#438DD5,stroke:#2E6295,color:#fff

    class svc1 service
    class db,redis,rabbit database
EOF

# Create L3 diagram
cat > "$L3_DIAGRAM" << EOF
%% L3 Component Diagram: ${DOMAIN_NAME}
%% C4 Model Level 3 - Component view

graph TB
    subgraph service["Service"]
        api["API Layer"]
        core["Business Logic"]
        data["Data Access"]
    end

    api --> core
    core --> data

    classDef component fill:#85BBF0,stroke:#5D82A8,color:#000
    class api,core,data component
EOF

echo -e "${GREEN}Created domain: $DOMAIN_FILE${NC}"
echo -e "${GREEN}Created diagram: $L2_DIAGRAM${NC}"
echo -e "${GREEN}Created diagram: $L3_DIAGRAM${NC}"
echo ""
echo "Next steps:"
echo "  1. Update $DOMAIN_FILE with domain details"
echo "  2. Add entry to registry/domains.yaml:"
echo ""
echo "  - id: $DOMAIN_ID"
echo "    name: $DOMAIN_NAME"
echo "    slug: $DOMAIN_SLUG"
echo "    description: {description}"
echo "    owner: $OWNER"
echo "    services: []"
echo "    depends_on: []"
echo "    docs: domains/${DOMAIN_SLUG}.md"
echo "    diagrams:"
echo "      L2: diagrams/L2/${DOMAIN_SLUG}.mmd"
echo "      L3: diagrams/L3/${DOMAIN_SLUG}.mmd"
