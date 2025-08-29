#!/bin/bash
set -euo pipefail

# This hook runs before Nextcloud starts. It ensures our custom app is available,
# fixes permissions, enables the app, and applies configuration from env vars.

APP_ID="webhook_rabbitmq"
NC_DIR="/var/www/html"
APPS_DIR="$NC_DIR/custom_apps"
SRC_DIR="/usr/src/nextcloud/custom_apps/$APP_ID"

echo "[hook] Ensuring $APP_ID is present in $APPS_DIR"
mkdir -p "$APPS_DIR"
if [ -d "$SRC_DIR" ]; then
  # Sync baked app into the persistent volume if missing or empty
  if [ ! -d "$APPS_DIR/$APP_ID" ] || [ -z "$(ls -A "$APPS_DIR/$APP_ID" 2>/dev/null || true)" ]; then
    echo "[hook] Copying $APP_ID from image to persistent apps dir"
    cp -a "$SRC_DIR" "$APPS_DIR/"
  fi
fi

chown -R www-data:www-data "$APPS_DIR" || true

# Clean up problematic app configuration before enabling
if [ -x "$NC_DIR/occ" ]; then
  echo "[hook] Cleaning up problematic app configuration"
  # Remove the problematic 'enabled' key that can contain "1" instead of proper JSON
  runuser -u www-data -- php "$NC_DIR/occ" config:app:delete "$APP_ID" enabled 2>/dev/null || true
  
  echo "[hook] Enabling app $APP_ID (if not already)"
  runuser -u www-data -- php -d memory_limit=512M "$NC_DIR/occ" app:enable "$APP_ID" || true
fi

# Apply configuration from environment variables NC_webhook_rabbitmq_* if provided
apply_cfg() {
  local key="$1"; local val="$2"
  if [ -n "${val}" ]; then
    echo "[hook] Setting app config $key"
    runuser -u www-data -- php "$NC_DIR/occ" config:app:set "$APP_ID" "$key" --value="$val" || true
  fi
}

# No need for enabled/publish_enabled - if app is enabled in Nextcloud, it works
apply_cfg host "${NC_webhook_rabbitmq_host:-}"
apply_cfg port "${NC_webhook_rabbitmq_port:-}"
apply_cfg user "${NC_webhook_rabbitmq_user:-}"
apply_cfg pass "${NC_webhook_rabbitmq_pass:-}"
apply_cfg vhost "${NC_webhook_rabbitmq_vhost:-}"
apply_cfg exchange "${NC_webhook_rabbitmq_exchange:-}"
apply_cfg exchange_type "${NC_webhook_rabbitmq_exchange_type:-}"
apply_cfg routing_prefix "${NC_webhook_rabbitmq_routing_prefix:-}"

echo "[hook] $APP_ID configuration hook completed"

