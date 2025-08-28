#!/bin/bash
set -euo pipefail

: "${SSH_SERVER:?Missing SSH_SERVER}"
: "${SSH_USER:?Missing SSH_USER}"
: "${SSH_PASSWORD:?Missing SSH_PASSWORD}"

ASK=/workspace/.remote/askpass_nc.sh
mkdir -p /workspace/.remote
cat >"$ASK" <<'EOS'
#!/bin/sh
printf %s "$SSH_PASSWORD"
EOS
chmod 700 "$ASK"

export DISPLAY=:0
export SSH_ASKPASS="$ASK"

SSHOPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

echo "→ Fixing Nextcloud apps/custom_apps permissions and restarting..."
setsid -w ssh $SSHOPTS "$SSH_USER@$SSH_SERVER" "cd /srv/docker/nc-rag && \
docker compose exec -T nextcloud bash -lc 'set -e; mkdir -p /var/www/html/custom_apps; chown -R www-data:www-data /var/www/html/apps /var/www/html/custom_apps || true; ls -ld /var/www/html/apps /var/www/html/custom_apps; php -l /var/www/html/custom_apps/webhook_rabbitmq/appinfo/routes.php || true' && \
docker compose restart nextcloud" | cat

echo "✅ Permissions fixed and Nextcloud restarted"

