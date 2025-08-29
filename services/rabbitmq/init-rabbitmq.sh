#!/bin/bash
set -e

# Custom RabbitMQ initialization script
# This script runs after RabbitMQ starts and sets up users, queues, and exchanges

echo "🐰 Starting RabbitMQ post-initialization..."

# Wait for RabbitMQ to be ready
echo "⏳ Waiting for RabbitMQ to start..."
timeout=60
while ! rabbitmqctl status >/dev/null 2>&1; do
    sleep 1
    timeout=$((timeout - 1))
    if [ $timeout -eq 0 ]; then
        echo "❌ Timeout waiting for RabbitMQ to start"
        exit 1
    fi
done

echo "✅ RabbitMQ is running"

# Create vhost if not exists
echo "🏠 Creating vhost..."
VHOST="${RABBITMQ_DEFAULT_VHOST:-ncrag}"
if ! rabbitmqctl list_vhosts | grep -q "^${VHOST}$"; then
    rabbitmqctl add_vhost "${VHOST}"
    echo "✅ VHost ${VHOST} created"
else
    echo "ℹ️  VHost ${VHOST} already exists"
fi

# Create application user if not exists
echo "👤 Creating application user..."
if ! rabbitmqctl list_users | grep -q "^${RABBITMQ_APP_USER:-ncrag-app}"; then
    rabbitmqctl add_user "${RABBITMQ_APP_USER:-ncrag-app}" "${RABBITMQ_APP_PASS:-ncragapppass}"
    echo "✅ User ${RABBITMQ_APP_USER:-ncrag-app} created"
else
    echo "ℹ️  User ${RABBITMQ_APP_USER:-ncrag-app} already exists"
    # Update password in case it changed
    rabbitmqctl change_password "${RABBITMQ_APP_USER:-ncrag-app}" "${RABBITMQ_APP_PASS:-ncragapppass}"
fi

# Set permissions for users
echo "🔐 Setting permissions..."
# Permissions for main user on the vhost
rabbitmqctl set_permissions -p "${VHOST}" "${RABBITMQ_DEFAULT_USER:-ncrag}" ".*" ".*" ".*"
# Permissions for application user on the vhost
rabbitmqctl set_permissions -p "${VHOST}" "${RABBITMQ_APP_USER:-ncrag-app}" ".*" ".*" ".*"

# Declare exchanges
echo "📡 Creating exchanges..."
rabbitmqadmin -u "${RABBITMQ_DEFAULT_USER:-ncrag}" -p "${RABBITMQ_DEFAULT_PASS:-ncragpass}" -V "${VHOST}" declare exchange name=ncrag.events type=direct durable=true

# Declare queues
echo "📥 Creating queues..."

# Queue for file events from Node-RED
rabbitmqadmin -u "${RABBITMQ_DEFAULT_USER:-ncrag}" -p "${RABBITMQ_DEFAULT_PASS:-ncragpass}" -V "${VHOST}" declare queue name=events.files durable=true arguments='{"x-message-ttl":86400000,"x-max-length":10000}'

# Queue for processed files ready for ingestion
rabbitmqadmin -u "${RABBITMQ_DEFAULT_USER:-ncrag}" -p "${RABBITMQ_DEFAULT_PASS:-ncragpass}" -V "${VHOST}" declare queue name=ingest.ready durable=true arguments='{"x-message-ttl":86400000,"x-max-length":10000}'

# Queue for failed processing (dead letter)
rabbitmqadmin -u "${RABBITMQ_DEFAULT_USER:-ncrag}" -p "${RABBITMQ_DEFAULT_PASS:-ncragpass}" -V "${VHOST}" declare queue name=events.failed durable=true arguments='{"x-message-ttl":604800000}'

# Bind queues to exchange
echo "🔗 Binding queues to exchanges..."
rabbitmqadmin -u "${RABBITMQ_DEFAULT_USER:-ncrag}" -p "${RABBITMQ_DEFAULT_PASS:-ncragpass}" -V "${VHOST}" declare binding source=ncrag.events destination=events.files routing_key=file.event
rabbitmqadmin -u "${RABBITMQ_DEFAULT_USER:-ncrag}" -p "${RABBITMQ_DEFAULT_PASS:-ncragpass}" -V "${VHOST}" declare binding source=ncrag.events destination=ingest.ready routing_key=ingest.ready

# Set up dead letter exchange and binding
rabbitmqadmin -u "${RABBITMQ_DEFAULT_USER:-ncrag}" -p "${RABBITMQ_DEFAULT_PASS:-ncragpass}" -V "${VHOST}" declare exchange name=ncrag.dlx type=direct durable=true
rabbitmqadmin -u "${RABBITMQ_DEFAULT_USER:-ncrag}" -p "${RABBITMQ_DEFAULT_PASS:-ncragpass}" -V "${VHOST}" declare binding source=ncrag.dlx destination=events.failed routing_key=failed

echo "✅ RabbitMQ initialization completed!"

# Display queue status
echo "📊 Queue status:"
rabbitmqctl list_queues name messages consumers

echo "🎯 RabbitMQ is ready for NC-RAG system!"
