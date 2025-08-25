#!/usr/bin/env bash
set -euo pipefail

# This hook runs inside the Nextcloud container before Apache starts.
# It installs/enables Talk (spreed) and ensures a service bot user exists.

NC_DIR="/var/www/html"
OCC="php -d memory_limit=512M ${NC_DIR}/occ"

as_www() {
  # Run a command as the web server user
  if command -v runuser >/dev/null 2>&1; then
    runuser -u www-data -- "$@"
  else
    su -s /bin/sh -c "$*" www-data
  fi
}

occ() {
  as_www ${OCC} "$@"
}

log() {
  echo "[hook:nextcloud-config] $*"
}

# Wait until Nextcloud is installed (occ status returns installed: true)
is_installed() {
  as_www ${OCC} status | grep -q "installed: true" || return 1
}

if ! is_installed; then
  log "Nextcloud not installed yet. Skipping Talk/bot provisioning for now."
  exit 0
fi

log "Ensuring Talk (spreed) app is installed and enabled"
if ! occ app:list | grep -qE '^[[:space:]]+- spreed: enabled$'; then
  # Try enable first; if missing, install then enable
  if ! occ app:enable spreed >/dev/null 2>&1; then
    log "Installing spreed app"
    occ app:install spreed || true
    occ app:enable spreed || true
  fi
fi

# Create/update bot user if credentials are provided
BOT_USER="${NEXTCLOUD_BOT_USER:-}"
BOT_PASS="${NEXTCLOUD_BOT_PASSWORD:-}"
BOT_NAME="${NEXTCLOUD_BOT_DISPLAY_NAME:-Service Bot}"

if [[ -n "${BOT_USER}" && -n "${BOT_PASS}" ]]; then
  if occ user:info "${BOT_USER}" >/dev/null 2>&1; then
    log "Bot user '${BOT_USER}' already exists"
    # Ensure display name is set (best effort)
    occ user:modify --display-name "${BOT_NAME}" "${BOT_USER}" >/dev/null 2>&1 || \
      occ user:setting "${BOT_USER}" settings displayName "${BOT_NAME}" >/dev/null 2>&1 || true
  else
    log "Creating bot user '${BOT_USER}'"
    # Pass OC_PASS explicitly through env to the www-data context
    as_www env OC_PASS="${BOT_PASS}" ${OCC} user:add --password-from-env --display-name "${BOT_NAME}" "${BOT_USER}" || true
    # Ensure Talk app is available to bot (default is yes if app enabled)
  fi
else
  log "NEXTCLOUD_BOT_USER/NEXTCLOUD_BOT_PASSWORD not set; skipping bot user creation"
fi

log "Hook finished"