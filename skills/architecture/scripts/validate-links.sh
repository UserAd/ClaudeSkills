#!/usr/bin/env bash
# Validate cross-references in architecture documentation
#
# Checks:
# - Service IDs in registry/services.yaml exist in services/*.md
# - Domain IDs in registry/domains.yaml exist in domains/*.md
# - Contract links in services point to existing files
# - Technology IDs in services exist in tech-radar.yaml

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [arch_dir]

Validate cross-references in architecture documentation.
Run from git root directory.

Arguments:
  arch_dir    Path to .architecture directory (default: git_root/.architecture)

Options:
  -h, --help  Show this help message

Checks:
  - Service docs paths in registry/services.yaml exist
  - Domain docs paths in registry/domains.yaml exist
  - Diagram paths in registry/domains.yaml exist
  - Domain IDs referenced by services exist in domains.yaml
  - Technology IDs in services.yaml exist in tech-radar.yaml

Examples:
  $(basename "$0")                        # Check git_root/.architecture
  $(basename "$0") /path/to/.architecture # Check specific directory
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

ERRORS=0

echo "Checking cross-references..."

# Check services registry vs service files
if [[ -f "$ARCH_DIR/registry/services.yaml" ]]; then
    # Extract service docs paths
    while IFS= read -r doc_path; do
        if [[ -n "$doc_path" ]] && [[ ! -f "$ARCH_DIR/$doc_path" ]]; then
            echo -e "${RED}Missing service file: $ARCH_DIR/$doc_path${NC}"
            ERRORS=$((ERRORS + 1))
        fi
    done < <(grep -E "^\s+docs:" "$ARCH_DIR/registry/services.yaml" 2>/dev/null | sed 's/.*docs:[[:space:]]*//' | tr -d '"' | sed 's/^[[:space:]]*//' || true)
fi

# Check domains registry vs domain files
if [[ -f "$ARCH_DIR/registry/domains.yaml" ]]; then
    while IFS= read -r doc_path; do
        if [[ -n "$doc_path" ]] && [[ ! -f "$ARCH_DIR/$doc_path" ]]; then
            echo -e "${RED}Missing domain file: $ARCH_DIR/$doc_path${NC}"
            ERRORS=$((ERRORS + 1))
        fi
    done < <(grep -E "^\s+docs:" "$ARCH_DIR/registry/domains.yaml" 2>/dev/null | sed 's/.*docs:[[:space:]]*//' | tr -d '"' | sed 's/^[[:space:]]*//' || true)
fi

# Check diagram references
if [[ -f "$ARCH_DIR/registry/domains.yaml" ]]; then
    while IFS= read -r diagram_path; do
        if [[ -n "$diagram_path" ]] && [[ ! -f "$ARCH_DIR/$diagram_path" ]]; then
            echo -e "${RED}Missing diagram: $ARCH_DIR/$diagram_path${NC}"
            ERRORS=$((ERRORS + 1))
        fi
    done < <(grep -E "^\s+L[23]:" "$ARCH_DIR/registry/domains.yaml" 2>/dev/null | sed 's/.*:[[:space:]]*//' | tr -d '"' | sed 's/^[[:space:]]*//' || true)
fi

# Check domain IDs referenced by services exist in domains.yaml
if [[ -f "$ARCH_DIR/registry/services.yaml" ]] && [[ -f "$ARCH_DIR/registry/domains.yaml" ]]; then
    # Extract all domain IDs from domains.yaml (only DOM- prefixed entries)
    DOMAIN_IDS=$(grep -E "^\s+-?\s*id:\s*DOM-" "$ARCH_DIR/registry/domains.yaml" 2>/dev/null | sed 's/.*id:[[:space:]]*//' | tr -d '"' | sed 's/^[[:space:]]*//' || true)

    # Check each domain reference in services.yaml
    while IFS= read -r domain_ref; do
        if [[ -n "$domain_ref" ]] && ! echo "$DOMAIN_IDS" | grep -q "^${domain_ref}$"; then
            echo -e "${RED}Unknown domain ID in services.yaml: $domain_ref${NC}"
            ERRORS=$((ERRORS + 1))
        fi
    done < <(grep -E "^\s+domain:" "$ARCH_DIR/registry/services.yaml" 2>/dev/null | sed 's/.*domain:[[:space:]]*//' | tr -d '"' | sed 's/^[[:space:]]*//' || true)
fi

# Check technology IDs in services.yaml exist in tech-radar.yaml
if [[ -f "$ARCH_DIR/registry/services.yaml" ]] && [[ -f "$ARCH_DIR/registry/tech-radar.yaml" ]]; then
    # Extract all technology IDs from tech-radar.yaml (only TECH- prefixed entries)
    TECH_IDS=$(grep -E "^\s+-?\s*id:\s*TECH-" "$ARCH_DIR/registry/tech-radar.yaml" 2>/dev/null | sed 's/.*id:[[:space:]]*//' | tr -d '"' | sed 's/^[[:space:]]*//' || true)

    # Check each technology reference in services.yaml (under technologies: list)
    while IFS= read -r tech_ref; do
        if [[ -n "$tech_ref" ]] && ! echo "$TECH_IDS" | grep -q "^${tech_ref}$"; then
            echo -e "${RED}Unknown technology ID in services.yaml: $tech_ref${NC}"
            ERRORS=$((ERRORS + 1))
        fi
    done < <(grep -oE "TECH-[A-Z0-9-]+" "$ARCH_DIR/registry/services.yaml" 2>/dev/null || true)
fi

if [[ $ERRORS -eq 0 ]]; then
    echo -e "${GREEN}All cross-references valid${NC}"
    exit 0
else
    echo -e "${RED}Found $ERRORS broken reference(s)${NC}"
    exit 1
fi
