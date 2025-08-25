# NC-RAG Deployment Instructions

**Server:** ncrag.voronkov.club  
**User:** root  
**Project Path:** /srv/docker/nc-rag  

## Quick Deployment

### Option 1: Manual SSH Deployment

```bash
# 1. SSH to server
ssh root@ncrag.voronkov.club

# 2. Navigate to project
cd /srv/docker/nc-rag

# 3. Run deployment script (uploaded via WebDAV)
cp /var/www/nextcloud/data/admin/files/server_deploy_script.sh .
chmod +x server_deploy_script.sh
./server_deploy_script.sh
```

### Option 2: Step-by-Step Manual Deployment

```bash
# 1. SSH to server
ssh root@ncrag.voronkov.club

# 2. Navigate and update
cd /srv/docker/nc-rag
git pull origin main

# 3. Configure environment
cp .env.example .env
nano .env  # Edit with production values

# 4. Deploy services
docker compose down
docker compose up -d --build

# 5. Verify deployment
docker compose ps
./scripts/test-phase4.sh
```

## Required Environment Variables

Edit `.env` file with these production values:

```bash
# Nextcloud (use current password)
NEXTCLOUD_ADMIN_PASSWORD=j*yDCX<4ubIj_.w##>lhxDc?

# RabbitMQ (set secure passwords)
RABBITMQ_APP_PASS=secure-rabbitmq-app-password

# Parser (set secure secret)
PARSER_SECRET=secure-parser-secret

# Worker settings (optional, defaults are fine)
WORKER_CONCURRENCY=2
WORKER_PREFETCH=1

# Talk bot (optional but recommended)
NEXTCLOUD_BOT_USER=bot
NEXTCLOUD_BOT_PASSWORD=<secure-password>
NEXTCLOUD_BOT_DISPLAY_NAME=Service Bot
```

## Verification Steps

After deployment, verify these endpoints:

1. **RabbitMQ Management:** https://ncrag.voronkov.club/rabbitmq/
   - Should return 401 (requires auth)
   - Login: admin/admin

2. **Parser Endpoint:** https://ncrag.voronkov.club/webhooks/parser/
   - Should return 200 with JSON response

3. **Node-RED Webhook:** https://ncrag.voronkov.club/nodered/webhooks/nextcloud
   - Should return 401 (requires webhook secret)

## Testing Integration

```bash
# Upload test file to trigger processing
echo "Test file for Phase 4" > /tmp/test_phase4.txt
curl -T /tmp/test_phase4.txt \
  "https://ncrag.voronkov.club/remote.php/dav/files/admin/test_phase4.txt" \
  -u "admin:j*yDCX<4ubIj_.w##>lhxDc?"

# Monitor processing
docker compose logs worker --tail=20
docker compose exec redis redis-cli keys "job:*"
docker compose exec rabbitmq rabbitmqctl list_queues
```

## Troubleshooting

### Common Issues

1. **Services not starting:**
   ```bash
   docker compose logs [service_name]
   docker system prune -f
   docker compose up -d --build
   ```

2. **Worker can't connect to RabbitMQ:**
   ```bash
   docker compose exec rabbitmq rabbitmqctl list_users
   docker compose exec rabbitmq rabbitmqctl list_permissions
   ```

3. **Redis connection issues:**
   ```bash
   docker compose exec redis redis-cli ping
   ```

### Service Status Check

```bash
# All services should show "Up"
docker compose ps

# Key services to verify:
# - nextcloud (already running)
# - rabbitmq (Phase 3)
# - node-red (Phase 3)
# - worker (Phase 4)
# - redis (Phase 4)
# - mock-parser (Phase 4)
```

## Expected Results

After successful deployment:

- ✅ File uploads trigger webhook events
- ✅ Node-RED processes and queues events
- ✅ Worker consumes events and processes files
- ✅ Jobs are submitted to parser and tracked in Redis
- ✅ Full pipeline: File → Webhook → Queue → Worker → Parser

## Monitoring Commands

```bash
# Worker activity
docker compose logs -f worker

# Queue status
docker compose exec rabbitmq rabbitmqctl list_queues name messages

# Job tracking
docker compose exec redis redis-cli keys "job:*"
docker compose exec redis redis-cli get "job:JOBID"

# Service health
curl https://ncrag.voronkov.club/webhooks/parser/health
```