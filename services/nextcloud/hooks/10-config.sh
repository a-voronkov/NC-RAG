#!/bin/bash
set -euo pipefail

# This hook runs before Nextcloud starts. It ensures our custom app is available,
# fixes permissions, enables the app, applies configuration from env vars, and
# guarantees PHP session storage is ready.

APP_ID="webhook_rabbitmq"
NC_DIR="/var/www/html"
APPS_DIR="$NC_DIR/custom_apps"
SRC_DIR="/usr/src/nextcloud/custom_apps/$APP_ID"

# Helper to run occ as www-data when possible
occ() {
  if [ -x "$NC_DIR/occ" ]; then
    if command -v runuser >/dev/null 2>&1 && [ "$(id -u)" -eq 0 ]; then
      runuser -u www-data -- php -d memory_limit=512M "$NC_DIR/occ" "$@"
    else
      php -d memory_limit=512M "$NC_DIR/occ" "$@"
    fi
  fi
}

# Ensure PHP session directory exists and owned by www-data
# session.save_path is configured to /var/www/html/data/sessions in zzzz-session.ini
if [ ! -d "$NC_DIR/data/sessions" ]; then
  mkdir -p "$NC_DIR/data/sessions"
fi
if [ "$(id -u)" -eq 0 ]; then
  chown -R www-data:www-data "$NC_DIR/data" || true
fi

echo "[hook] Ensuring $APP_ID is present in $APPS_DIR"
mkdir -p "$APPS_DIR"
if [ -d "$SRC_DIR" ]; then
  # Sync baked app into the persistent volume if missing or empty
  if [ ! -d "$APPS_DIR/$APP_ID" ] || [ -z "$(ls -A "$APPS_DIR/$APP_ID" 2>/dev/null || true)" ]; then
    echo "[hook] Copying $APP_ID from image to persistent apps dir"
    cp -a "$SRC_DIR" "$APPS_DIR/"
  fi
fi

if [ "$(id -u)" -eq 0 ]; then
  chown -R www-data:www-data "$APPS_DIR" || true
fi

# Enable the app if available
if [ -x "$NC_DIR/occ" ]; then
  echo "[hook] Enabling app $APP_ID (if not already)"
  occ app:enable "$APP_ID" || true
fi

# Apply configuration from environment variables NC_webhook_rabbitmq_* if provided
apply_cfg() {
  local key="$1"; local val="${2:-}"
  if [ -n "${val}" ]; then
    echo "[hook] Setting app config $key"
    occ config:app:set "$APP_ID" "$key" --value="$val" || true
  fi
}

apply_cfg enabled "${NC_webhook_rabbitmq_enabled:-}"
apply_cfg host "${NC_webhook_rabbitmq_host:-}"
apply_cfg port "${NC_webhook_rabbitmq_port:-}"
apply_cfg user "${NC_webhook_rabbitmq_user:-}"
apply_cfg pass "${NC_webhook_rabbitmq_pass:-}"
apply_cfg vhost "${NC_webhook_rabbitmq_vhost:-}"
apply_cfg exchange "${NC_webhook_rabbitmq_exchange:-}"
apply_cfg exchange_type "${NC_webhook_rabbitmq_exchange_type:-}"
apply_cfg routing_prefix "${NC_webhook_rabbitmq_routing_prefix:-}"

# Ensure overwrite.cli.url matches public domain (behind Traefik)
PUBLIC_DOMAIN="${NEXTCLOUD_DOMAIN:-}"
if [ -z "$PUBLIC_DOMAIN" ] && [ -n "${NEXTCLOUD_TRUSTED_DOMAINS:-}" ]; then
  # take the first domain from trusted domains string (space/comma separated)
  PUBLIC_DOMAIN="${NEXTCLOUD_TRUSTED_DOMAINS%%[ ,]*}"
fi
if [ -n "$PUBLIC_DOMAIN" ]; then
  echo "[hook] Ensuring overwrite.cli.url=https://$PUBLIC_DOMAIN"
  occ config:system:set overwrite.cli.url --value="https://$PUBLIC_DOMAIN" || true
fi

echo "[hook] $APP_ID configuration hook completed"

