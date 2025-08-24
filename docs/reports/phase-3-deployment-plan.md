# Phase 3 Deployment Plan

**Target Server:** ncrag.voronkov.club  
**Status:** Ready for deployment  
**Date:** 2025-01-19

## Pre-Deployment Checklist

### 1. Verify Current Server State
```bash
# SSH to server
ssh root@ncrag.voronkov.club

# Navigate to project directory
cd /srv/docker/nc-rag

# Check current status
docker compose ps
git status
ls -la
```

### 2. Backup Current Configuration
```bash
# Create backup
cp docker-compose.yml docker-compose.yml.backup
cp -r services/ services.backup/

# Commit current changes
git add .
git commit -m "Backup before Phase 3 deployment" || true
```

## Deployment Steps

### 3. Sync Repository Changes
```bash
# Pull latest changes from repository
git fetch origin
git reset --hard origin/main

# Or manually copy files if needed:
# - .env.example (new)
# - docker-compose.yml (updated with RabbitMQ)
# - services/node-red/flows.json (updated with AMQP)
# - scripts/rabbitmq-init.sh (new)
```

### 4. Environment Configuration
```bash
# Create/update .env file
cp .env.example .env

# Edit .env with production values
nano .env

# Required variables:
# NEXTCLOUD_DOMAIN=ncrag.voronkov.club
# NEXTCLOUD_ADMIN_USER=admin
# NEXTCLOUD_ADMIN_PASSWORD=<current-password>
# POSTGRES_PASSWORD=<current-db-password>
# WEBHOOK_SECRET=<current-webhook-secret>
# RABBITMQ_PASSWORD=<secure-password>
# RABBITMQ_APP_PASS=<secure-app-password>
```

### 5. Deploy Services
```bash
# Stop current services
docker compose down

# Build updated Node-RED with AMQP support
docker compose build --no-cache node-red

# Start all services
docker compose up -d

# Wait for services to start
sleep 30
```

### 6. Verify Deployment
```bash
# Check service status
docker compose ps

# Check logs for errors
docker compose logs rabbitmq
docker compose logs node-red
docker compose logs traefik

# Verify RabbitMQ initialization
docker compose exec rabbitmq rabbitmqctl list_queues
```

## Testing Phase 3 Gates

### Gate 1: RabbitMQ Queue Infrastructure
```bash
# Access RabbitMQ Management UI
# URL: https://ncrag.voronkov.club/rabbitmq/
# Credentials: admin/admin (default)

# Verify queues exist:
# - events.files
# - ingest.ready  
# - events.failed

# Check queue properties:
# - TTL: 24h for active queues
# - Max length: 10,000 messages
# - Durability: true
```

### Gate 2: HTTPS Parser Webhook Route
```bash
# Test parser webhook endpoint
curl -I https://ncrag.voronkov.club/webhooks/parser

# Expected: 200 OK or 401 Unauthorized (both indicate route works)
# Must have valid TLS certificate
```

### Gate 3: Message Flow Testing
```bash
# Upload a test file to Nextcloud
# Monitor RabbitMQ queues for new messages

# Check webhook log
docker compose exec node-red cat /data/webhook-log.jsonl | tail -5

# Check RabbitMQ queue depth
docker compose exec rabbitmq rabbitmqctl list_queues name messages
```

## Validation Commands

### Service Health Checks
```bash
# All services running
docker compose ps | grep -v "Exit"

# RabbitMQ responsive
docker compose exec rabbitmq rabbitmqctl status

# Node-RED responsive  
curl -s https://ncrag.voronkov.club/nodered/

# Traefik routing working
curl -I https://ncrag.voronkov.club/webhooks/parser
```

### Integration Testing
```bash
# Test file upload webhook flow
# 1. Upload file via Nextcloud UI
# 2. Check webhook delivery in Node-RED logs
# 3. Verify message in RabbitMQ events.files queue
# 4. Confirm no errors in service logs
```

## Success Criteria

### Phase 3 Gate Requirements
- ✅ RabbitMQ deployed with management UI
- ✅ Queues declared: events.files, ingest.ready  
- ✅ Node-RED publishing to events.files queue
- ✅ Messages appear for create/update/delete/share events

### Phase 3b Gate Requirements  
- ✅ HTTPS parser webhook route functional
- ✅ Valid TLS certificate on /webhooks/parser
- ✅ Proper routing and middleware configuration

## Troubleshooting

### Common Issues
1. **RabbitMQ fails to start**
   - Check volume permissions
   - Verify environment variables
   - Check available memory

2. **Node-RED can't connect to RabbitMQ**
   - Verify AMQP credentials in flows.json
   - Check network connectivity
   - Confirm RabbitMQ user permissions

3. **Webhook delivery fails**
   - Check Nextcloud webhook configuration
   - Verify secret matches in .env
   - Test Node-RED endpoint directly

### Recovery Plan
```bash
# If deployment fails, rollback:
docker compose down
cp docker-compose.yml.backup docker-compose.yml
cp -r services.backup/* services/
docker compose up -d
```

## Next Steps After Successful Deployment

1. **Update Phase 3 completion status**
2. **Begin Phase 4 planning** - Go Worker development
3. **Monitor system performance** - RabbitMQ resource usage
4. **Document any deployment-specific configurations**

---

**Deployment Status:** 🚀 Ready for execution  
**Estimated Time:** 15-30 minutes  
**Risk Level:** Low (incremental changes with rollback plan)