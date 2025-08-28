#!/bin/bash
set -euo pipefail

: "${SSH_SERVER:?Missing SSH_SERVER}"
: "${SSH_USER:?Missing SSH_USER}"
: "${SSH_PASSWORD:?Missing SSH_PASSWORD}"

REMOTE_DIR="/srv/docker/nc-rag"
APP_DIR_CONTAINER="/var/www/html/apps/webhook_rabbitmq"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=15 -o NumberOfPasswordPrompts=1"

have_sshpass() { command -v sshpass >/dev/null 2>&1; }

ensure_askpass() {
  if have_sshpass; then return 0; fi
  ASKPASS="$(mktemp -p "${TMPDIR:-/tmp}" askpass.XXXXXX)"
  cat >"${ASKPASS}" <<'EOS'
#!/bin/sh
printf %s "$SSH_PASSWORD"
EOS
  chmod 700 "${ASKPASS}"
}

run_ssh() {
  if have_sshpass; then
    sshpass -p "$SSH_PASSWORD" ssh ${SSH_OPTS} "$@"
  else
    ensure_askpass
    DISPLAY=:0 SSH_ASKPASS="${ASKPASS}" setsid -w ssh ${SSH_OPTS} "$@"
  fi
}

echo "→ Deploying webhook_rabbitmq app into Nextcloud container..."
run_ssh "${SSH_USER}@${SSH_SERVER}" bash -lc "set -e; cd '${REMOTE_DIR}'; \
docker compose exec nextcloud bash -lc 'mkdir -p /var/www/html/apps && rm -rf ${APP_DIR_CONTAINER}'; \
docker compose cp ./webhook_rabbitmq nextcloud:/var/www/html/apps/; \
docker compose exec nextcloud bash -lc 'chown -R www-data:www-data ${APP_DIR_CONTAINER}'; \
docker compose exec nextcloud bash -lc "grep -n '<script>' ${APP_DIR_CONTAINER}/templates/admin.php || true"; \
echo '✓ App deployed'"

echo "✅ Done"

