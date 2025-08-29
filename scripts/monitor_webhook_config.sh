#!/bin/bash
set -euo pipefail

# Script to monitor webhook_rabbitmq app configuration changes
# This helps debug what's writing the problematic 'enabled' key

echo "🔍 Monitoring webhook_rabbitmq app configuration..."

APP_ID="webhook_rabbitmq"

# Check if we're running inside the Nextcloud container
if [ ! -f "/var/www/html/occ" ]; then
    echo "❌ This script must be run inside the Nextcloud container"
    echo "Run: docker compose exec nextcloud bash /scripts/monitor_webhook_config.sh"
    exit 1
fi

echo "📋 Current app configuration:"
echo "=== All app config keys ==="
php /var/www/html/occ config:app:get $APP_ID --output=json || echo "No config found"

echo ""
echo "=== Specific keys ==="
echo "enabled: $(php /var/www/html/occ config:app:get $APP_ID enabled 2>/dev/null || echo 'NOT SET')"
echo "publish_enabled: $(php /var/www/html/occ config:app:get $APP_ID publish_enabled 2>/dev/null || echo 'NOT SET')"

echo ""
echo "📊 App status:"
php /var/www/html/occ app:list | grep $APP_ID || echo "App not found in list"

echo ""
echo "🔍 App enabled status in database:"
# Check the database directly
php -r "
\$config = \OC::\$server->getConfig();
\$enabled = \$config->getAppValue('$APP_ID', 'enabled', 'NOT_SET');
\$publishEnabled = \$config->getAppValue('$APP_ID', 'publish_enabled', 'NOT_SET');
echo \"enabled key: \" . var_export(\$enabled, true) . \"\\n\";
echo \"publish_enabled key: \" . var_export(\$publishEnabled, true) . \"\\n\";
"

echo ""
echo "✅ Configuration monitoring completed!"
