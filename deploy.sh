#!/bin/bash
set -e

echo "=== NC-RAG Deployment Script ==="
echo "Server: $SSH_SERVER"
echo "User: $SSH_USER"
echo ""

echo "📋 Manual deployment steps:"
echo "1. SSH to server: ssh $SSH_USER@$SSH_SERVER"
echo "2. Navigate to project: cd /srv/docker/nc-rag"
echo "3. Pull latest changes: git pull origin main"
echo "4. Update environment: cp .env.example .env && nano .env"
echo "5. Deploy services: docker compose down && docker compose up -d --build"
echo "6. Check status: docker compose ps"
echo "7. Test Phase 4: ./scripts/test-phase4.sh"
echo ""

echo "🔍 Key services to verify:"
echo "- RabbitMQ Management: https://$SSH_SERVER/rabbitmq/"
echo "- Mock Parser: https://$SSH_SERVER/webhooks/parser/"
echo "- Nextcloud: https://$SSH_SERVER/"
echo ""

echo "📊 Monitoring commands:"
echo "- Worker logs: docker compose logs worker"
echo "- Redis jobs: docker compose exec redis redis-cli keys 'job:*'"
echo "- RabbitMQ queues: docker compose exec rabbitmq rabbitmqctl list_queues"