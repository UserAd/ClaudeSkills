#!/bin/bash
# Kamailio configuration syntax checker
# Usage: check-kamailio.sh [config_file]
# Default: kamailio/kamailio.cfg

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(cd "$SKILL_DIR/../../.." && pwd)"

CONFIG_FILE="${1:-kamailio/kamailio.cfg}"
DOCKERFILE="$SKILL_DIR/assets/Dockerfile.kamailio-test"
IMAGE_NAME="kamailio-test"

# Resolve config path relative to project root if not absolute
if [[ ! "$CONFIG_FILE" = /* ]]; then
    CONFIG_FILE="$PROJECT_ROOT/$CONFIG_FILE"
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config file not found: $CONFIG_FILE" >&2
    exit 1
fi

# Build Docker image if it doesn't exist
if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
    echo "Building $IMAGE_NAME Docker image..."
    docker build --platform linux/amd64 \
        -t "$IMAGE_NAME" \
        -f "$DOCKERFILE" \
        "$SKILL_DIR/assets/" >/dev/null 2>&1
    echo "Image built successfully."
fi

# Run syntax check
echo "Checking: $CONFIG_FILE"
echo "---"

docker run --rm --platform linux/amd64 \
    -v "$CONFIG_FILE:/tmp/kamailio.cfg.template:ro" \
    "$IMAGE_NAME" \
    bash -c 'sed -e "s/DB_NAME/testdb/g" \
                 -e "s/DB_USER/testuser/g" \
                 -e "s/DB_PASSWORD/testpass/g" \
                 -e "s/DB_HOST/127.0.0.1/g" \
                 -e "s/DOMAIN/localhost/g" \
                 -e "s/ADVERTISE_IP/127.0.0.1/g" \
             /tmp/kamailio.cfg.template > /etc/kamailio/kamailio.cfg && \
             kamailio -c -f /etc/kamailio/kamailio.cfg 2>&1'

exit_code=$?
echo "---"
if [[ $exit_code -eq 0 ]]; then
    echo "Result: PASS"
else
    echo "Result: FAIL (exit code: $exit_code)"
fi

exit $exit_code
