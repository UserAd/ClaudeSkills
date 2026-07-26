#!/usr/bin/env bash
# Architecture validation script
# Validates .architecture directory using yamllint, markdownlint-cli2, and mermaid lint
#
# Usage:
#   ./scripts/validate.sh [arch_dir]
#
# Arguments:
#   arch_dir - Path to .architecture directory (default: .architecture in git root)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [arch_dir]

Validate architecture documentation.

Arguments:
  arch_dir    Path to .architecture directory (default: git root/.architecture)

Options:
  -h, --help  Show this help message

Validators:
  - yamllint          YAML syntax validation
  - markdownlint-cli2 Markdown style validation
  - lint-mermaid.mjs  Mermaid diagram syntax validation
  - validate-links.sh Cross-reference integrity

Examples:
  $(basename "$0")                        # Validate in git root
  $(basename "$0") /path/to/.architecture # Validate specific directory
EOF
    exit 0
}

# Parse help flag
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    show_help
fi

# Find git root
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")

# Architecture directory
ARCH_DIR="${1:-$GIT_ROOT/.architecture}"

if [[ ! -d "$ARCH_DIR" ]]; then
    echo -e "${RED}Error: Architecture directory not found: $ARCH_DIR${NC}"
    echo "Initialize with: architecture init"
    exit 1
fi

echo "Validating architecture at: $ARCH_DIR"
echo "----------------------------------------"

ERRORS=0

# Check if yamllint is installed
if command -v yamllint &> /dev/null; then
    echo -e "${YELLOW}Running yamllint...${NC}"
    if yamllint -c "$ARCH_DIR/.yamllint.yml" "$ARCH_DIR/registry/"*.yaml 2>/dev/null; then
        echo -e "${GREEN}YAML validation passed${NC}"
    else
        echo -e "${RED}YAML validation failed${NC}"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "${YELLOW}Warning: yamllint not installed. Skipping YAML validation.${NC}"
    echo "Install with: pip install yamllint"
fi

# Check if markdownlint-cli2 is installed
if command -v markdownlint-cli2 &> /dev/null; then
    echo -e "${YELLOW}Running markdownlint-cli2...${NC}"
    if (cd "$ARCH_DIR" && markdownlint-cli2 "**/*.md" 2>/dev/null); then
        echo -e "${GREEN}Markdown validation passed${NC}"
    else
        echo -e "${RED}Markdown validation failed${NC}"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "${YELLOW}Warning: markdownlint-cli2 not installed. Skipping Markdown validation.${NC}"
    echo "Install with: npm install -g markdownlint-cli2"
fi

# Check if node is installed for mermaid linting
if command -v node &> /dev/null; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -f "$ARCH_DIR/node_modules/.bin/mermaid" ]] || [[ -f "$SCRIPT_DIR/lint-mermaid.mjs" ]]; then
        echo -e "${YELLOW}Running mermaid lint...${NC}"

        # Check if dependencies are installed
        if [[ -d "$ARCH_DIR/node_modules" ]]; then
            cd "$ARCH_DIR"
            if node "$SCRIPT_DIR/lint-mermaid.mjs" "diagrams/**/*.mmd" "**/*.md"; then
                echo -e "${GREEN}Mermaid validation passed${NC}"
            else
                echo -e "${RED}Mermaid validation failed${NC}"
                ERRORS=$((ERRORS + 1))
            fi
            cd - > /dev/null
        else
            echo -e "${YELLOW}Warning: Node modules not installed. Run 'npm install' in $ARCH_DIR${NC}"
        fi
    fi
else
    echo -e "${YELLOW}Warning: node not installed. Skipping Mermaid validation.${NC}"
fi

# Validate cross-references
echo -e "${YELLOW}Validating cross-references...${NC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/validate-links.sh" ]]; then
    if bash "$SCRIPT_DIR/validate-links.sh" "$ARCH_DIR"; then
        echo -e "${GREEN}Cross-reference validation passed${NC}"
    else
        echo -e "${RED}Cross-reference validation failed${NC}"
        ERRORS=$((ERRORS + 1))
    fi
fi

echo "----------------------------------------"
if [[ $ERRORS -eq 0 ]]; then
    echo -e "${GREEN}All validations passed!${NC}"
    exit 0
else
    echo -e "${RED}Validation failed with $ERRORS error(s)${NC}"
    exit 1
fi
