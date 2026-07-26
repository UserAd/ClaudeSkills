#!/usr/bin/env bash
# Generate HTTP API index from contracts
#
# Scans contracts/http/*.md to build an index of APIs.
#
# Usage:
#   ./scripts/generate-http-apis.sh [arch_dir]

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [arch_dir]

Generate HTTP API index from contract files.
Run from git root directory.

Arguments:
  arch_dir    Path to .architecture directory (default: git_root/.architecture)

Options:
  -h, --help  Show this help message

Scans:
  - contracts/http/*.md for API definitions

Output:
  - registry/http-apis.yaml

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

OUTPUT_FILE="$ARCH_DIR/registry/http-apis.yaml"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Start YAML output
cat > "$OUTPUT_FILE" << EOF
# HTTP API Index - GENERATED from contracts/http/*.md
_meta:
  generated_at: "$TIMESTAMP"
  source: contracts/http/*.md

apis:
EOF

# Parse HTTP contracts
if [[ -d "$ARCH_DIR/contracts/http" ]]; then
    for contract in "$ARCH_DIR/contracts/http"/*.md; do
        [[ -f "$contract" ]] || continue
        [[ "$(basename "$contract")" == "_template.md" ]] && continue

        name=$(basename "$contract" .md)

        # Extract fields from blockquote frontmatter: > **Key:** Value | **Key2:** ...
        # Extract base URL/path
        base_url=$(sed -n 's/.*\*\*Base [PU][a-z]*:\*\*[[:space:]]*\([^|]*\).*/\1/p' "$contract" | head -1 | tr -d '`' | sed 's/[[:space:]]*$//' || true)

        # Extract owner (try Owner: first, then Consumer:)
        owner=$(sed -n 's/.*\*\*Owner:\*\*[[:space:]]*\([^|]*\).*/\1/p' "$contract" | head -1 | sed 's/[[:space:]]*$//' || true)
        if [[ -z "$owner" ]]; then
            owner=$(sed -n 's/.*\*\*Consumer:\*\*[[:space:]]*\([^|]*\).*/\1/p' "$contract" | head -1 | sed 's/[[:space:]]*$//' || true)
        fi

        # Extract version
        version=$(sed -n 's/.*\*\*Version:\*\*[[:space:]]*\([^|]*\).*/\1/p' "$contract" | head -1 | sed 's/[[:space:]]*$//' || echo "v1")

        cat >> "$OUTPUT_FILE" << EOF
  - name: $name
    base_url: ${base_url:-/api/$name}
    version: ${version:-v1}
    owner: ${owner:-unknown}
    contract: contracts/http/${name}.md
EOF
    done
fi

echo -e "${GREEN}Generated: $OUTPUT_FILE${NC}"
