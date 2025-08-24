# Phase 3 Plan - Queue Layer (RabbitMQ)

## Overview

Phase 3 focuses on adding RabbitMQ as a message queue layer between Node-RED and future processing workers. This will provide reliable message delivery and decoupling between webhook reception and file processing.

## Current State Analysis

**Completed (Phase 2):**
- ✅ Node-RED receiving webhooks from Nextcloud
- ✅ HTTPS fronting with Traefik + Let's Encrypt
- ✅ Webhook authentication and normalization
- ✅ Events logged to `/data/webhook-log.jsonl`

**Phase 3b Status:**
- ✅ Traefik with Let's Encrypt already deployed
- ✅ Route `/nodered/webhooks/nextcloud` → Node-RED working
- ⚠️ Need to add route `/webhooks/parser` → future worker
- ⚠️ Need to protect RabbitMQ management UI

## Phase 3 Tasks

### 1. RabbitMQ Deployment
- Add RabbitMQ service to `docker-compose.yml`
- Configure with custom credentials (not guest/guest)
- Enable management UI on internal network only
- Set up persistent volumes for queue data

### 2. Queue Declaration
- Create queue: `events.files` for file events from Node-RED
- Create queue: `ingest.ready` for processed files ready for ingestion
- Configure appropriate queue settings (durability, etc.)

### 3. Node-RED Integration
- Add AMQP node to Node-RED
- Modify flow to publish normalized events to `events.files` queue
- Maintain existing logging for debugging
- Add error handling for queue connection issues

### 4. HTTPS Routes (Phase 3b completion)
- Add route `/webhooks/parser` for future parser webhooks
- Implement basic auth or IP restrictions for admin UIs
- Test TLS certificate validity

### 5. Testing & Verification
- Test file upload → message in `events.files` queue
- Verify message format and content
- Test queue persistence and reliability
- Confirm HTTPS routes work correctly

## Implementation Steps

1. **Update docker-compose.yml** with RabbitMQ service
2. **Create RabbitMQ initialization script** for queues and users
3. **Update Node-RED flow** to publish to queue
4. **Add Traefik labels** for parser webhook route
5. **Create verification scripts** for testing
6. **Update documentation** and reports

## Expected Deliverables

- Updated `docker-compose.yml` with RabbitMQ
- Modified Node-RED flow with AMQP publishing
- RabbitMQ initialization script
- Updated Traefik configuration
- Phase 3 completion report
- Verification evidence

## Dependencies

- RabbitMQ Docker image
- Node-RED AMQP nodes (node-red-contrib-amqp)
- Environment variables for RabbitMQ credentials

## Risks & Considerations

1. **Resource Usage:** RabbitMQ will add ~100-200MB RAM usage
2. **Network:** Need internal network for RabbitMQ communication
3. **Persistence:** Queue data should survive container restarts
4. **Security:** Proper credentials and network isolation
5. **Monitoring:** Management UI access for debugging

## Success Criteria

- File events flow: Nextcloud → Node-RED → RabbitMQ queue
- Messages persist in queue and can be consumed
- HTTPS routes properly configured
- All security requirements met
- Performance acceptable on 4GB/2vCPU server