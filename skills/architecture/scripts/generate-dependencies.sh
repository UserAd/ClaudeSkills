#!/usr/bin/env bash
# Generate dependency graph from contracts
#
# Scans contracts/rabbitmq/*.md and contracts/http/*.md to build
# a dependency graph showing producer/consumer relationships.
#
# Usage:
#   ./scripts/generate-dependencies.sh [arch_dir]

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [arch_dir]

Generate dependency graph from contract files.
Run from git root directory.

Arguments:
  arch_dir    Path to .architecture directory (default: git_root/.architecture)

Options:
  -h, --help  Show this help message

Scans:
  - contracts/rabbitmq/*.md for producer/consumer relationships
  - contracts/http/*.md for client/server relationships

Output:
  - registry/dependencies.yaml

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

OUTPUT_FILE="$ARCH_DIR/registry/dependencies.yaml"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Create temp files for collecting data (portable approach for bash 3.2)
TEMP_DIR=$(mktemp -d)
PRODUCES_FILE="$TEMP_DIR/produces.txt"
CONSUMES_FILE="$TEMP_DIR/consumes.txt"
touch "$PRODUCES_FILE" "$CONSUMES_FILE"

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Parse RabbitMQ contracts for producers/consumers
if [[ -d "$ARCH_DIR/contracts/rabbitmq" ]]; then
    for contract in "$ARCH_DIR/contracts/rabbitmq"/*.md; do
        [[ -f "$contract" ]] || continue
        [[ "$(basename "$contract")" == "_template.md" ]] && continue

        exchange=$(basename "$contract" .md)

        # Extract owner (producer) from contract
        # Handles formats: "**Owner:** SVC-X" or "> **Type:** x | **Owner:** SVC-X"
        owner=$(grep -E "\*\*Owner:\*\*|^owner:" "$contract" 2>/dev/null \
            | head -1 \
            | sed -E 's/.*\*\*Owner:\*\*[[:space:]]*//' \
            | sed 's/[[:space:]]*|.*//' \
            | tr -d '`*' \
            | sed 's/^[[:space:]]*//' || true)

        if [[ -n "$owner" ]] && [[ "$owner" =~ ^SVC- ]]; then
            echo "$owner|$exchange" >> "$PRODUCES_FILE"
        fi

        # Extract consumers from contract
        # Look for "**Consumer:**" or "**Consumers:**" patterns
        grep -E "\*\*Consumer[s]?:\*\*" "$contract" 2>/dev/null \
            | sed -E 's/.*\*\*Consumer[s]?:\*\*[[:space:]]*//' \
            | tr ',' '\n' \
            | sed 's/[[:space:]]*|.*//' \
            | tr -d '`*' \
            | sed 's/^[[:space:]]*//' \
            | sed 's/[[:space:]]*$//' \
            | while read -r consumer; do
                if [[ -n "$consumer" ]] && [[ "$consumer" =~ ^SVC- ]]; then
                    echo "$consumer|$exchange" >> "$CONSUMES_FILE"
                fi
            done || true
    done
fi

# Parse HTTP contracts for client/server relationships
if [[ -d "$ARCH_DIR/contracts/http" ]]; then
    for contract in "$ARCH_DIR/contracts/http"/*.md; do
        [[ -f "$contract" ]] || continue
        [[ "$(basename "$contract")" == "_template.md" ]] && continue

        api=$(basename "$contract" .md)

        # Extract server (owner) from contract
        server=$(grep -E "\*\*Owner:\*\*|\*\*Server:\*\*|^owner:" "$contract" 2>/dev/null \
            | head -1 \
            | sed -E 's/.*\*\*(Owner|Server):\*\*[[:space:]]*//' \
            | sed 's/[[:space:]]*|.*//' \
            | tr -d '`*' \
            | sed 's/^[[:space:]]*//' || true)

        if [[ -n "$server" ]] && [[ "$server" =~ ^SVC- ]]; then
            echo "$server|http:$api" >> "$PRODUCES_FILE"
        fi
    done
fi

# Generate YAML output header
cat > "$OUTPUT_FILE" << EOF
# Dependency Graph - GENERATED from contracts/
# Run: ./scripts/generate-dependencies.sh
_meta:
  generated_at: "$TIMESTAMP"
  generator: scripts/generate-dependencies.sh

graph:
EOF

# Check if we have any data
if [[ ! -s "$PRODUCES_FILE" ]] && [[ ! -s "$CONSUMES_FILE" ]]; then
    echo "  # No services found in contracts" >> "$OUTPUT_FILE"
else
    # Get sorted unique list of all services
    cat "$PRODUCES_FILE" "$CONSUMES_FILE" | cut -d'|' -f1 | sort -u > "$TEMP_DIR/services.txt"

    while read -r svc; do
        [[ -z "$svc" ]] && continue

        echo "  $svc:" >> "$OUTPUT_FILE"

        # Get produces list (sorted, unique)
        produces=$(grep "^$svc|" "$PRODUCES_FILE" 2>/dev/null | cut -d'|' -f2 | sort -u || true)
        if [[ -n "$produces" ]]; then
            echo "    produces:" >> "$OUTPUT_FILE"
            echo "$produces" | while read -r item; do
                [[ -n "$item" ]] && echo "      - $item" >> "$OUTPUT_FILE"
            done
        else
            echo "    produces: []" >> "$OUTPUT_FILE"
        fi

        # Get consumes list (sorted, unique)
        consumes=$(grep "^$svc|" "$CONSUMES_FILE" 2>/dev/null | cut -d'|' -f2 | sort -u || true)
        if [[ -n "$consumes" ]]; then
            echo "    consumes:" >> "$OUTPUT_FILE"
            echo "$consumes" | while read -r item; do
                [[ -n "$item" ]] && echo "      - $item" >> "$OUTPUT_FILE"
            done
        else
            echo "    consumes: []" >> "$OUTPUT_FILE"
        fi
    done < "$TEMP_DIR/services.txt"
fi

echo -e "${GREEN}Generated: $OUTPUT_FILE${NC}"
