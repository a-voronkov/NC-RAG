#!/bin/bash
set -euo pipefail

# Script to fix webhook_rabbitmq app configuration in Nextcloud
# This fixes the issue where the app's enabled config contains "1" instead of proper JSON

echo "🔧 Fixing webhook_rabbitmq app configuration..."

# Check if we're running inside the Nextcloud container
if [ ! -f "/var/www/html/occ" ]; then
    echo "❌ This script must be run inside the Nextcloud container"
    echo "Run: docker compose exec nextcloud bash /scripts/fix_webhook_app_config.sh"
    exit 1
fi

APP_ID="webhook_rabbitmq"

echo "📋 Current app configuration:"
php /var/www/html/occ config:app:get $APP_ID enabled || echo "No 'enabled' config found"

echo "🧹 Cleaning up problematic app configuration..."

# Remove the problematic 'enabled' key that contains "1"
php /var/www/html/occ config:app:delete $APP_ID enabled || true

echo "🔄 Disabling and re-enabling the app..."
# Disable the app first
php /var/www/html/occ app:disable $APP_ID || true

# Re-enable the app (this should set proper configuration)
php /var/www/html/occ app:enable $APP_ID

echo "📋 New app configuration:"
php /var/www/html/occ config:app:get $APP_ID enabled || echo "No 'enabled' config found (this is good)"

echo "📊 App status:"
php /var/www/html/occ app:list | grep $APP_ID || echo "App not found in list"

echo "✅ webhook_rabbitmq app configuration fixed!"
echo "ℹ️  You may need to refresh the Nextcloud admin page to see the settings again."
