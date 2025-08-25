#!/bin/bash

# Remote deployment commands for NC-RAG Phase 4
echo "=== Remote Deployment Commands ==="
echo "Execute these commands on the server:"
echo ""

cat << 'EOF'
# 1. Navigate to project directory
cd /srv/docker/nc-rag

# 2. Check current status
git status
docker compose ps

# 3. Pull latest changes
git pull origin main

# 4. Update environment file
cp .env.example .env
# Edit .env with production values:
# - NEXTCLOUD_ADMIN_PASSWORD (current password)
# - RABBITMQ_APP_PASS (secure password)
# - PARSER_SECRET (secure secret)

# 5. Build and deploy new services
docker compose down
docker compose build --no-cache worker
docker compose up -d

# 6. Verify deployment
docker compose ps
docker compose logs worker --tail=20
docker compose logs redis --tail=10

# 7. Test Phase 4
chmod +x scripts/test-phase4.sh
./scripts/test-phase4.sh

# 8. Monitor services
docker compose exec redis redis-cli keys "job:*"
docker compose exec rabbitmq rabbitmqctl list_queues
EOF