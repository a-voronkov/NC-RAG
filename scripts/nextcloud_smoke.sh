#!/usr/bin/env bash
set -euo pipefail

NC_URL="${NEXTCLOUD_URL:-http://localhost:8081}"
NC_USER="${NEXTCLOUD_USER:-admin}"
NC_PASS="${NEXTCLOUD_PASS:-adminpass}"

TMPFILE="/tmp/nc-smoke-$$.txt"
echo "hello world" > "$TMPFILE"

echo "Uploading via WebDAV..."
curl -fsS -u "$NC_USER:$NC_PASS" -T "$TMPFILE" "$NC_URL/remote.php/dav/files/$NC_USER/smoke.txt"

echo "Downloading via WebDAV..."
DOWN="$(curl -fsS -u "$NC_USER:$NC_PASS" "$NC_URL/remote.php/dav/files/$NC_USER/smoke.txt")"

if [[ "$DOWN" == "hello world" ]]; then
  echo "Smoke test OK"
else
  echo "Smoke test FAILED" >&2
  exit 1
fi

