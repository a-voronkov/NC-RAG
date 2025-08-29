#!/bin/bash
set -e

# Custom entrypoint for RabbitMQ with post-initialization
echo "🚀 Starting RabbitMQ with custom initialization..."

# Start RabbitMQ in background
echo "🐰 Starting RabbitMQ server..."
rabbitmq-server &
RABBITMQ_PID=$!

# Function to cleanup on exit
cleanup() {
    echo "🛑 Shutting down RabbitMQ..."
    kill $RABBITMQ_PID 2>/dev/null || true
    wait $RABBITMQ_PID 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# Wait a bit for RabbitMQ to start, then run initialization
sleep 10
echo "🔧 Running initialization script..."
/usr/local/bin/init-rabbitmq.sh &

# Wait for RabbitMQ process
wait $RABBITMQ_PID
