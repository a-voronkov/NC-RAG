#!/bin/bash
set -e

# RabbitMQ Initialization Script
# This script sets up queues and exchanges for the NC-RAG system

echo "🐰 Starting RabbitMQ initialization..."

# Wait for RabbitMQ to be ready
echo "⏳ Waiting for RabbitMQ to start..."
rabbitmqctl wait --timeout 60 /var/lib/rabbitmq/mnesia/rabbit@$HOSTNAME.pid

# Ensure default vhost exists before setting permissions
VHOST="${RABBITMQ_DEFAULT_VHOST:-ncrag}"
if ! rabbitmqctl list_vhosts | awk 'NR>1{print $1}' | grep -Fx "$VHOST" >/dev/null; then
  echo "➕ Adding vhost $VHOST"
  rabbitmqctl add_vhost "$VHOST"
fi

# Create application user if not exists
echo "👤 Creating application user..."
rabbitmqctl add_user ${RABBITMQ_APP_USER:-ncrag-app} ${RABBITMQ_APP_PASS:-ncragapppass} 2>/dev/null || true

# Set permissions for application user
echo "🔐 Setting permissions..."
rabbitmqctl set_permissions -p "$VHOST" ${RABBITMQ_APP_USER:-ncrag-app} ".*" ".*" ".*"

# Declare exchanges
echo "📡 Creating exchanges..."
rabbitmqadmin declare exchange name=ncrag.events type=direct durable=true

# Declare queues
echo "📥 Creating queues..."

# Queue for file events from Node-RED
rabbitmqadmin declare queue name=events.files durable=true arguments='{"x-message-ttl":86400000,"x-max-length":10000}'

# Queue for processed files ready for ingestion
rabbitmqadmin declare queue name=ingest.ready durable=true arguments='{"x-message-ttl":86400000,"x-max-length":10000}'

# Queue for failed processing (dead letter)
rabbitmqadmin declare queue name=events.failed durable=true arguments='{"x-message-ttl":604800000}'

# Bind queues to exchange
echo "🔗 Binding queues to exchanges..."
rabbitmqadmin declare binding source=ncrag.events destination=events.files routing_key=file.event
rabbitmqadmin declare binding source=ncrag.events destination=ingest.ready routing_key=ingest.ready

# Set up dead letter exchange and binding
rabbitmqadmin declare exchange name=ncrag.dlx type=direct durable=true
rabbitmqadmin declare binding source=ncrag.dlx destination=events.failed routing_key=failed

echo "✅ RabbitMQ initialization completed!"

# Display queue status
echo "📊 Queue status:"
rabbitmqctl list_queues name messages consumers

echo "🎯 RabbitMQ is ready for NC-RAG system!"