#!/bin/bash
set -e

echo "=== NC-RAG Server Deployment Script ==="
echo "Starting deployment at $(date)"
echo ""

# Navigate to project directory
cd /srv/docker/nc-rag
echo "✅ Current directory: $(pwd)"

# Check git status
echo "📋 Git status before update:"
git status --porcelain

# Pull latest changes
echo "🔄 Pulling latest changes..."
git pull origin main

# Show what changed
echo "📊 Recent commits:"
git log --oneline -3

# Check current docker status
echo "🐳 Current Docker services:"
docker compose ps

# Update environment file if needed
if [ ! -f .env ]; then
    echo "📝 Creating .env file..."
    cp .env.example .env
    echo "⚠️  Please edit .env with production values before continuing"
    echo "   Key variables to set:"
    echo "   - NEXTCLOUD_ADMIN_PASSWORD"
    echo "   - RABBITMQ_APP_PASS"
    echo "   - PARSER_SECRET"
    echo ""
    echo "   Run: nano .env"
    echo "   Then continue with: docker compose up -d --build"
    exit 0
fi

# Deploy services
echo "🚀 Deploying services..."
docker compose down
echo "Building services (this may take a few minutes)..."
docker compose build --no-cache worker
echo "Starting all services..."
docker compose up -d

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 15

# Check deployment status
echo "📊 Deployment status:"
docker compose ps

# Check logs for any immediate errors
echo "📋 Recent logs:"
echo "--- Worker logs ---"
docker compose logs worker --tail=5
echo "--- Redis logs ---"
docker compose logs redis --tail=3
echo "--- RabbitMQ logs ---"
docker compose logs rabbitmq --tail=3

# Test basic connectivity
echo "🧪 Testing basic connectivity..."
echo "RabbitMQ Management UI:"
curl -s -o /dev/null -w "  Status: %{http_code}\n" "https://ncrag.voronkov.club/rabbitmq/" || echo "  Failed to connect"

echo "Parser endpoint:"
curl -s -o /dev/null -w "  Status: %{http_code}\n" "https://ncrag.voronkov.club/webhooks/parser/" || echo "  Failed to connect"

echo "Node-RED webhook:"
curl -s -o /dev/null -w "  Status: %{http_code}\n" "https://ncrag.voronkov.club/nodered/webhooks/nextcloud" || echo "  Failed to connect"

# Run integration test if available
if [ -f "./scripts/test-phase4.sh" ]; then
    echo "🧪 Running integration tests..."
    chmod +x ./scripts/test-phase4.sh
    ./scripts/test-phase4.sh
else
    echo "⚠️  Integration test script not found"
fi

echo ""
echo "✅ Deployment completed at $(date)"
echo "🔍 Monitor services with:"
echo "   docker compose logs -f worker"
echo "   docker compose exec redis redis-cli keys 'job:*'"
echo "   docker compose exec rabbitmq rabbitmqctl list_queues"