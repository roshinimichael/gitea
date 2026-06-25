#!/bin/bash
set -euo pipefail

COMPOSE_FILE=".skyramp/sut/docker-compose.testbot.yml"
BASE_URL="http://localhost:3000"
ADMIN_USER="testbot-admin"
ADMIN_PASS="testbotAdmin123"
ADMIN_EMAIL="admin@testbot.com"

# Wait for Gitea to be healthy
echo "Waiting for Gitea API to be ready..." >&2
timeout 300 bash -c "until curl -sf ${BASE_URL}/api/v1/version > /dev/null 2>&1; do sleep 3; done" || {
  echo "ERROR: Gitea did not become ready within 300s" >&2
  exit 1
}

# Create admin user with an access token (must run as 'git' user inside the container)
echo "Creating admin user '${ADMIN_USER}'..." >&2
CREATE_OUTPUT=$(docker compose -f "$COMPOSE_FILE" --project-directory . exec -T --user git gitea \
  /usr/local/bin/gitea admin user create \
  --admin \
  --username "$ADMIN_USER" \
  --password "$ADMIN_PASS" \
  --email "$ADMIN_EMAIL" \
  --must-change-password=false \
  --access-token \
  --access-token-name testbot-token \
  --access-token-scopes all 2>&1) || true

TOKEN=$(echo "$CREATE_OUTPUT" | grep "Access token was successfully created" | awk '{print $NF}')

if [ -z "$TOKEN" ]; then
  echo "User creation output: $CREATE_OUTPUT" >&2
  # Fallback: generate token via REST API (user may already exist on retry)
  echo "Attempting token generation via API..." >&2
  TOKEN=$(curl -sf -X POST "${BASE_URL}/api/v1/users/${ADMIN_USER}/tokens" \
    -H "Content-Type: application/json" \
    -u "${ADMIN_USER}:${ADMIN_PASS}" \
    -d '{"name":"testbot-token-retry","scopes":["all"]}' | jq -r '.sha1')
fi

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "ERROR: Could not obtain API token" >&2
  exit 1
fi

echo "$TOKEN"
