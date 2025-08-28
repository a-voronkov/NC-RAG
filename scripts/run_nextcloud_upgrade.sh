#!/bin/bash
set -euo pipefail

: "${SSH_SERVER:?Missing SSH_SERVER}"
: "${SSH_USER:?Missing SSH_USER}"
: "${SSH_PASSWORD:?Missing SSH_PASSWORD}"

ASK=/workspace/.remote/askpass_nc_upgrade.sh
mkdir -p /workspace/.remote
cat >"$ASK" <<'EOS'
#!/bin/sh
printf %s "$SSH_PASSWORD"
EOS
chmod 700 "$ASK"

export DISPLAY=:0
export SSH_ASKPASS="$ASK"

SSHOPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

echo "→ Running Nextcloud CLI upgrade..."
setsid -w ssh $SSHOPTS "$SSH_USER@$SSH_SERVER" "cd /srv/docker/nc-rag && \
docker compose exec -T -u www-data nextcloud php occ status || true && \
docker compose exec -T -u www-data nextcloud php occ maintenance:mode --on || true && \
docker compose exec -T -u www-data nextcloud php occ upgrade && \
docker compose exec -T -u www-data nextcloud php occ maintenance:mode --off && \
docker compose exec -T -u www-data nextcloud php occ status && \
docker compose exec -T -u www-data nextcloud php occ app:list | grep -E "webhook_rabbitmq|Enabled:" -n || true" | cat

echo "✅ Nextcloud upgrade finished"

