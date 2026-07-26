#!/usr/bin/env bash
# Generate state storage index from contracts
#
# Scans contracts/state/*.md to build an index of state keys/tables.
#
# Usage:
#   ./scripts/generate-state-keys.sh [arch_dir]

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [arch_dir]

Generate state storage index from contract files.
Run from git root directory.

Arguments:
  arch_dir    Path to .architecture directory (default: git_root/.architecture)

Options:
  -h, --help  Show this help message

Scans:
  - contracts/state/*.md for state storage definitions

Output:
  - registry/state-keys.yaml

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

OUTPUT_FILE="$ARCH_DIR/registry/state-keys.yaml"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Start YAML output
cat > "$OUTPUT_FILE" << EOF
# State Storage Index - GENERATED from contracts/state/*.md
_meta:
  generated_at: "$TIMESTAMP"
  source: contracts/state/*.md

keys:
EOF

# Parse state contracts
if [[ -d "$ARCH_DIR/contracts/state" ]]; then
    for contract in "$ARCH_DIR/contracts/state"/*.md; do
        [[ -f "$contract" ]] || continue
        [[ "$(basename "$contract")" == "_template.md" ]] && continue

        name=$(basename "$contract" .md)

        # Extract storage type from contract (redis, postgres, clickhouse, mongodb)
        # Handles formats: "**Storage:** Redis" or "> **Owner:** SVC-X | **Storage:** PostgreSQL"
        storage=$(grep -E "\*\*Storage:\*\*|^storage:" "$contract" 2>/dev/null | head -1 | sed -E 's/.*\*\*Storage:\*\*[[:space:]]*//' | sed 's/[[:space:]]*|.*//' | tr -d '`*' | sed 's/^[[:space:]]*//' || echo "redis")

        # Extract owner from contract
        # Handles formats: "**Owner:** SVC-X" or "> **Owner:** SVC-X | **Storage:** Y"
        owner=$(grep -E "\*\*Owner:\*\*|^owner:" "$contract" 2>/dev/null | head -1 | sed -E 's/.*\*\*Owner:\*\*[[:space:]]*//' | sed 's/[[:space:]]*|.*//' | tr -d '`*' | sed 's/^[[:space:]]*//' || true)

        # Extract TTL if present (for redis)
        ttl=$(grep -E "^\*\*TTL:\*\*|^ttl:" "$contract" 2>/dev/null | head -1 | sed 's/.*[:|]\s*//' | tr -d '`*' | sed 's/^[[:space:]]*//' || true)

        cat >> "$OUTPUT_FILE" << EOF
  - name: $name
    storage: ${storage:-redis}
    owner: ${owner:-unknown}
    contract: contracts/state/${name}.md
EOF
        if [[ -n "$ttl" ]]; then
            echo "    ttl: $ttl" >> "$OUTPUT_FILE"
        fi
    done
fi

echo -e "${GREEN}Generated: $OUTPUT_FILE${NC}"
