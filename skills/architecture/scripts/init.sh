#!/usr/bin/env bash
# Initialize .architecture directory in git root
#
# Usage:
#   ./scripts/init.sh [target_dir]
#
# Arguments:
#   target_dir - Target directory (default: git root)

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [target_dir]

Initialize .architecture directory with full structure.

Arguments:
  target_dir    Target directory (default: git root)

Options:
  -h, --help    Show this help message

Examples:
  $(basename "$0")                    # Initialize in git root
  $(basename "$0") /path/to/project   # Initialize in specific directory
EOF
    exit 0
}

# Parse arguments
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    show_help
fi

# Find git root or use provided path
if [[ $# -gt 0 ]]; then
    TARGET_DIR="$1"
else
    TARGET_DIR=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
fi

ARCH_DIR="$TARGET_DIR/.architecture"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(dirname "$SCRIPT_DIR")/templates"

if [[ -d "$ARCH_DIR" ]]; then
    echo -e "${YELLOW}Architecture directory already exists: $ARCH_DIR${NC}"
    echo "Use 'architecture validate' to check existing structure"
    exit 1
fi

echo "Initializing architecture at: $ARCH_DIR"

# Create directory structure
mkdir -p "$ARCH_DIR"/{registry,domains,services,contracts/{rabbitmq,http,state},schemas/{messages,api},diagrams/{L2,L3,flows},decisions,docs}

# Copy config files
cp "$TEMPLATE_DIR/.yamllint.yml" "$ARCH_DIR/"
cp "$TEMPLATE_DIR/.markdownlint.json" "$ARCH_DIR/"
cp "$TEMPLATE_DIR/.markdownlint-cli2.jsonc" "$ARCH_DIR/"
cp "$TEMPLATE_DIR/.markdownlintignore" "$ARCH_DIR/"
cp "$TEMPLATE_DIR/.gitignore" "$ARCH_DIR/"
cp "$TEMPLATE_DIR/package.json" "$ARCH_DIR/"
cp "$TEMPLATE_DIR/AGENTS.md" "$ARCH_DIR/"

# Copy templates tree (create-*.sh resolve ../templates relative to scripts/)
cp -R "$TEMPLATE_DIR" "$ARCH_DIR/templates"

# Copy registry templates
cp "$TEMPLATE_DIR/registry/domains.yaml" "$ARCH_DIR/registry/"
cp "$TEMPLATE_DIR/registry/services.yaml" "$ARCH_DIR/registry/"
cp "$TEMPLATE_DIR/registry/tech-radar.yaml" "$ARCH_DIR/registry/"
cp "$TEMPLATE_DIR/registry/glossary.yaml" "$ARCH_DIR/registry/"
cp "$TEMPLATE_DIR/registry/roles.yaml" "$ARCH_DIR/registry/"

# Create empty generated registry files
cat > "$ARCH_DIR/registry/dependencies.yaml" << 'EOF'
# Dependency Graph - GENERATED from contracts/
# Run: ./scripts/generate-dependencies.sh
_meta:
  generated_at: null
  generator: scripts/generate-dependencies.sh

graph: {}
EOF

cat > "$ARCH_DIR/registry/exchanges.yaml" << 'EOF'
# RabbitMQ Exchange Index - GENERATED from contracts/rabbitmq/*.md
_meta:
  generated_at: null
  source: contracts/rabbitmq/*.md

exchanges: []
EOF

cat > "$ARCH_DIR/registry/http-apis.yaml" << 'EOF'
# HTTP API Index - GENERATED from contracts/http/*.md
_meta:
  generated_at: null
  source: contracts/http/*.md

apis: []
EOF

cat > "$ARCH_DIR/registry/state-keys.yaml" << 'EOF'
# Redis State Index - GENERATED from contracts/state/*.md
_meta:
  generated_at: null
  source: contracts/state/*.md

keys: []
EOF

# Copy scripts directory
mkdir -p "$ARCH_DIR/scripts"
cp "$SCRIPT_DIR/lint-mermaid.mjs" "$ARCH_DIR/scripts/"
cp "$SCRIPT_DIR/validate.sh" "$ARCH_DIR/scripts/"
cp "$SCRIPT_DIR/validate-links.sh" "$ARCH_DIR/scripts/"
cp "$SCRIPT_DIR/create-domain.sh" "$ARCH_DIR/scripts/"
cp "$SCRIPT_DIR/create-service.sh" "$ARCH_DIR/scripts/"
cp "$SCRIPT_DIR/create-contract.sh" "$ARCH_DIR/scripts/"
cp "$SCRIPT_DIR/create-schema.sh" "$ARCH_DIR/scripts/"
cp "$SCRIPT_DIR/generate-dependencies.sh" "$ARCH_DIR/scripts/"
cp "$SCRIPT_DIR/generate-exchanges.sh" "$ARCH_DIR/scripts/"
cp "$SCRIPT_DIR/generate-http-apis.sh" "$ARCH_DIR/scripts/"
cp "$SCRIPT_DIR/generate-state-keys.sh" "$ARCH_DIR/scripts/"
chmod +x "$ARCH_DIR/scripts/"*.sh

# Create CONTRIBUTING.md
cat > "$ARCH_DIR/CONTRIBUTING.md" << 'EOF'
# Contributing to Architecture Documentation

**All scripts run from the git root directory** (where `.git` is located).

## Adding a New Service

```bash
# From git root:
.architecture/scripts/create-service.sh my-service --domain my-domain
```

Or manually:
1. Add entry to `.architecture/registry/services.yaml`
2. Create `.architecture/services/{name}.md` using template
3. Add contracts to `.architecture/contracts/rabbitmq/` or `.architecture/contracts/state/`
4. Run `.architecture/scripts/validate.sh` to verify

## Adding a New Domain

```bash
# From git root:
.architecture/scripts/create-domain.sh my-domain --id DOM-XX --owner team-name
```

Or manually:
1. Add entry to `.architecture/registry/domains.yaml`
2. Create `.architecture/domains/{slug}.md` using template
3. Create diagrams in `.architecture/diagrams/L2/` and `.architecture/diagrams/L3/`
4. Run `.architecture/scripts/validate.sh` to verify

## Validation

```bash
# From git root - run all validations
.architecture/scripts/validate.sh

# Install npm dependencies for mermaid linting
cd .architecture && npm install && cd ..

# Run via npm (from .architecture dir)
cd .architecture && npm run lint
```

## Naming Conventions

| Entity | Pattern | Example |
|--------|---------|---------|
| Domain ID | `DOM-{2-3 letters}` | `DOM-CC` |
| Service ID | `SVC-{NAME}` | `SVC-AGENTS` |
| Technology ID | `TECH-{NAME}` | `TECH-RUBY-3` |
| Domain file | `{slug}.md` | `contact-center.md` |
| Service file | `{name}.md` | `agents.md` |
EOF

echo -e "${GREEN}Architecture initialized at: $ARCH_DIR${NC}"
echo ""
echo "Next steps (run from git root):"
echo "  1. cd .architecture && npm install && cd .."
echo "  2. .architecture/scripts/create-domain.sh my-domain --id DOM-XX --owner team"
echo "  3. .architecture/scripts/create-service.sh my-service --domain my-domain"
echo "  4. .architecture/scripts/validate.sh"
