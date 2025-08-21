#!/usr/bin/env bash
set -euo pipefail

NC_URL="${NEXTCLOUD_URL:-http://localhost:8081}"
DEADLINE=$((SECONDS + ${WAIT_SECONDS:-180}))

echo "Waiting for Nextcloud at ${NC_URL} (status.php) ..."
while (( SECONDS < DEADLINE )); do
  if curl -fsS "${NC_URL}/status.php" | grep -q 'installed'; then
    echo "Nextcloud is up"
    exit 0
  fi
  sleep 3
done

echo "Timeout waiting for Nextcloud" >&2
exit 1

