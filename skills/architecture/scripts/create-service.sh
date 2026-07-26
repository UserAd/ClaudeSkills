#!/usr/bin/env bash
# Create a new service artifact
#
# Usage:
#   ./scripts/create-service.sh <service-name> [--domain DOM-XX] [--arch-dir path]
#
# Examples:
#   ./scripts/create-service.sh agents --domain DOM-CC
#   ./scripts/create-service.sh my-service

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

show_help() {
    cat << EOF
Usage: $(basename "$0") <service-name> [OPTIONS]

Create a new service artifact.

Arguments:
  service-name    Service name (e.g., agents, billing-api)

Options:
  --domain SLUG     Domain slug (e.g., contact-center, billing)
  --domain-id ID    Domain ID (e.g., DOM-CC) - optional, inferred from slug
  --arch-dir PATH   Architecture directory path
  -h, --help        Show this help message

Creates:
  - services/{name}.md  Service documentation

Examples:
  $(basename "$0") agents --domain contact-center
  $(basename "$0") billing-api --domain billing --domain-id DOM-BILL
EOF
    exit 0
}

# Parse arguments
SERVICE_NAME=""
DOMAIN_SLUG=""
DOMAIN_ID=""
ARCH_DIR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        --domain)
            DOMAIN_SLUG="$2"
            shift 2
            ;;
        --domain-id)
            DOMAIN_ID="$2"
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
            SERVICE_NAME="$1"
            shift
            ;;
    esac
done

if [[ -z "$SERVICE_NAME" ]]; then
    echo "Usage: $0 <service-name> [--domain SLUG] [--domain-id ID] [--arch-dir path]"
    exit 1
fi

# Infer domain ID from slug if not provided
if [[ -n "$DOMAIN_SLUG" ]] && [[ -z "$DOMAIN_ID" ]]; then
    # Convert slug to uppercase ID: contact-center -> DOM-CC (first letter of each word)
    DOMAIN_ID="DOM-$(echo "$DOMAIN_SLUG" | tr '-' '\n' | sed 's/^\(.\).*/\1/' | tr '[:lower:]' '[:upper:]' | tr -d '\n')"
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(dirname "$SCRIPT_DIR")/templates"

# Generate service ID (preserve hyphens, just uppercase)
SERVICE_ID="SVC-$(echo "$SERVICE_NAME" | tr '[:lower:]' '[:upper:]')"
SERVICE_FILE="$ARCH_DIR/services/${SERVICE_NAME}.md"

if [[ -f "$SERVICE_FILE" ]]; then
    echo -e "${RED}Error: Service file already exists: $SERVICE_FILE${NC}"
    exit 1
fi

# Create service documentation
cat > "$SERVICE_FILE" << EOF
# ${SERVICE_NAME}

> **ID:** ${SERVICE_ID} | **Domain:** [${DOMAIN_ID:-DOM-XX}](../domains/${DOMAIN_SLUG:-xx}.md) | **Status:** active

## Purpose

{1 sentence describing what this service does}

## Technology Stack

| Category | Technology | Radar Status |
|----------|------------|--------------|
| Runtime | Ruby 3.3 | Adopt |
| Database | PostgreSQL 15 | Adopt |
| Cache/State | Redis 7 | Adopt |
| Messaging | RabbitMQ 3.12 | Adopt |
| Testing | RSpec | Adopt |

> See [registry/tech-radar.yaml](../registry/tech-radar.yaml) for technology status.

**Repo:** \`org/${SERVICE_NAME}\`

## Configuration

| Env Var | Required | Description |
|---------|----------|-------------|
| \`RABBITMQ_URL\` | yes | Message broker connection |
| \`REDIS_URL\` | yes | State storage connection |
| \`DATABASE_URL\` | yes | PostgreSQL connection |

## Contracts

| Type | Link |
|------|------|
| RabbitMQ | [TBD](../contracts/rabbitmq/) |
| State | [TBD](../contracts/state/) |

## Commands

\`\`\`bash
# Start
foreman start

# Test
RAILS_ENV=test bundle exec rspec

# Lint
bundle exec rubocop
\`\`\`
EOF

echo -e "${GREEN}Created service: $SERVICE_FILE${NC}"
echo ""
echo "Next steps:"
echo "  1. Update $SERVICE_FILE with service details"
echo "  2. Add entry to registry/services.yaml:"
echo ""
echo "  - id: $SERVICE_ID"
echo "    name: $SERVICE_NAME"
echo "    domain: ${DOMAIN_ID:-DOM-XX}"
echo "    status: active"
echo "    repo: org/$SERVICE_NAME"
echo "    docs: services/${SERVICE_NAME}.md"
echo "    technologies:"
echo "      - TECH-RUBY-3"
echo "      - TECH-POSTGRES"
