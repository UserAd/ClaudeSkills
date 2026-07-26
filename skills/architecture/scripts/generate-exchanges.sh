#!/usr/bin/env bash
# Generate RabbitMQ exchange index from contracts
#
# Scans contracts/rabbitmq/*.md to build an index of exchanges.
#
# Usage:
#   ./scripts/generate-exchanges.sh [arch_dir]

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [arch_dir]

Generate RabbitMQ exchange index from contract files.
Run from git root directory.

Arguments:
  arch_dir    Path to .architecture directory (default: git_root/.architecture)

Options:
  -h, --help  Show this help message

Scans:
  - contracts/rabbitmq/*.md for exchange definitions

Output:
  - registry/exchanges.yaml

Examples:
  $(basename "$0")                        # Generate in git_root/.architecture
  $(basename "$0") /path/to/.architecture # Generate in specific directory
EOF
    exit 0
}

# Parse help flag
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    show_help
fi

# Find git root
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
ARCH_DIR="${1:-$GIT_ROOT/.architecture}"

if [[ ! -d "$ARCH_DIR" ]]; then
    echo -e "${YELLOW}Architecture directory not found: $ARCH_DIR${NC}"
    exit 1
fi

OUTPUT_FILE="$ARCH_DIR/registry/exchanges.yaml"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Start YAML output
cat > "$OUTPUT_FILE" << EOF
# RabbitMQ Exchange Index - GENERATED from contracts/rabbitmq/*.md
_meta:
  generated_at: "$TIMESTAMP"
  source: contracts/rabbitmq/*.md

exchanges:
EOF

# Parse RabbitMQ contracts
if [[ -d "$ARCH_DIR/contracts/rabbitmq" ]]; then
    for contract in "$ARCH_DIR/contracts/rabbitmq"/*.md; do
        [[ -f "$contract" ]] || continue
        [[ "$(basename "$contract")" == "_template.md" ]] && continue

        name=$(basename "$contract" .md)

        # Extract type from contract (default to topic)
        type=$(grep -E "^\*\*Type:\*\*|^type:" "$contract" 2>/dev/null | head -1 | sed 's/.*[:|]\s*//' | tr -d '`*' | sed 's/^[[:space:]]*//' || echo "topic")

        # Extract owner from contract
        owner=$(grep -E "^\*\*Owner:\*\*|^owner:" "$contract" 2>/dev/null | head -1 | sed 's/.*[:|]\s*//' | tr -d '`*' | sed 's/^[[:space:]]*//' || true)

        cat >> "$OUTPUT_FILE" << EOF
  - name: $name
    type: ${type:-topic}
    owner: ${owner:-unknown}
    contract: contracts/rabbitmq/${name}.md
EOF
    done
fi

echo -e "${GREEN}Generated: $OUTPUT_FILE${NC}"
