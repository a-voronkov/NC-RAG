#!/bin/bash
set -euo pipefail

: "${SSH_SERVER:?Missing SSH_SERVER}"
: "${SSH_USER:?Missing SSH_USER}"
: "${SSH_PASSWORD:?Missing SSH_PASSWORD}"

REMOTE_DIR="/srv/docker/nc-rag"
APP_NAME="webhook_rabbitmq"
APP_REMOTE_DIR="/var/www/html/custom_apps/${APP_NAME}"
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

echo "→ Syncing ${APP_NAME} into Nextcloud custom_apps..."
run_ssh "${SSH_USER}@${SSH_SERVER}" bash -lc "set -e; cd '${REMOTE_DIR}'; \
docker compose exec -T nextcloud bash -lc 'mkdir -p /var/www/html/custom_apps'; \
docker compose exec -T nextcloud bash -lc 'rm -rf ${APP_REMOTE_DIR}'; \
docker compose cp ./webhook_rabbitmq nextcloud:/var/www/html/custom_apps/; \
docker compose exec -T nextcloud bash -lc 'chown -R www-data:www-data ${APP_REMOTE_DIR}'; \
docker compose exec -T nextcloud bash -lc 'test -f ${APP_REMOTE_DIR}/js/admin.js && echo JS exists || (echo JS missing; exit 1)'; \
docker compose exec -T nextcloud bash -lc "! grep -q '<script>' ${APP_REMOTE_DIR}/templates/admin.php && echo 'Inline script not found' || (echo 'Inline script still present'; exit 1)"; \
docker compose restart nextcloud"

echo "✅ Nextcloud app synchronized."

