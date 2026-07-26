#!/usr/bin/env bash
# Create a new JSON schema artifact
#
# Usage:
#   ./scripts/create-schema.sh <type> <name> [--version v1] [--arch-dir path]
#
# Types: message, api
#
# Examples:
#   ./scripts/create-schema.sh message agent-state --version v2
#   ./scripts/create-schema.sh api agents-response

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

show_help() {
    cat << EOF
Usage: $(basename "$0") <type> <name> [OPTIONS]

Create a new JSON schema artifact.

Arguments:
  type    Schema type: message, api
  name    Schema name (e.g., agent-state, users-response)

Options:
  --version VERSION   Schema version (default: v1)
  --arch-dir PATH     Architecture directory path
  -h, --help          Show this help message

Creates:
  - schemas/messages/{name}.{version}.json  (for message type)
  - schemas/api/{name}.json                 (for api type)

Examples:
  $(basename "$0") message agent-state --version v2
  $(basename "$0") api agents-response
EOF
    exit 0
}

# Parse arguments
SCHEMA_TYPE=""
SCHEMA_NAME=""
VERSION="v1"
ARCH_DIR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        --version)
            VERSION="$2"
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
            if [[ -z "$SCHEMA_TYPE" ]]; then
                SCHEMA_TYPE="$1"
            else
                SCHEMA_NAME="$1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$SCHEMA_TYPE" ]] || [[ -z "$SCHEMA_NAME" ]]; then
    echo "Usage: $0 <type> <name> [--version v1] [--arch-dir path]"
    echo "Types: message, api"
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

case "$SCHEMA_TYPE" in
    message)
        SCHEMA_FILE="$ARCH_DIR/schemas/messages/${SCHEMA_NAME}.${VERSION}.json"
        ;;
    api)
        SCHEMA_FILE="$ARCH_DIR/schemas/api/${SCHEMA_NAME}.json"
        ;;
    *)
        echo -e "${RED}Error: Unknown schema type: $SCHEMA_TYPE${NC}"
        echo "Types: message, api"
        exit 1
        ;;
esac

if [[ -f "$SCHEMA_FILE" ]]; then
    echo -e "${RED}Error: Schema file already exists: $SCHEMA_FILE${NC}"
    exit 1
fi

# Convert name to title
SCHEMA_TITLE=$(echo "$SCHEMA_NAME" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1' | tr -d ' ')

# Extract version number
VERSION_NUM=$(echo "$VERSION" | tr -d 'v')

cat > "$SCHEMA_FILE" << EOF
{
  "\$schema": "http://json-schema.org/draft-07/schema#",
  "\$id": "${SCHEMA_NAME}-${VERSION}",
  "title": "${SCHEMA_TITLE}",
  "version": "${VERSION_NUM}.0.0",
  "description": "{Schema description}",
  "type": "object",
  "required": ["id", "timestamp"],
  "properties": {
    "id": {
      "type": "integer",
      "description": "Unique identifier"
    },
    "type": {
      "type": "string",
      "description": "Type field"
    },
    "data": {
      "type": "object",
      "description": "Payload data"
    },
    "timestamp": {
      "type": "string",
      "format": "date-time",
      "description": "ISO 8601 timestamp"
    }
  }
}
EOF

echo -e "${GREEN}Created schema: $SCHEMA_FILE${NC}"
echo ""
echo "Next steps:"
echo "  1. Update $SCHEMA_FILE with actual schema definition"
echo "  2. Reference from contract files"
