# Phase 4 Plan: Go Worker - Submit to Async Parser

**Owner:** agent  
**Start Date:** 2025-01-19  
**Dependencies:** Phase 3 (RabbitMQ) completed  
**Status:** Planning

## Objectives

Implement a Go worker service that:
1. Consumes file events from RabbitMQ `events.files` queue
2. Fetches files from Nextcloud via WebDAV/API
3. Submits files to external async parser service
4. Tracks job state and manages persistence
5. Handles errors and retries appropriately

## Architecture Overview

```
RabbitMQ (events.files) → Go Worker → External Parser API
                             ↓
                        Redis/DB (job state)
```

## Implementation Plan

### 1. Go Service Structure
```
services/worker/
├── main.go              # Entry point
├── config/
│   └── config.go        # Configuration management
├── consumer/
│   └── rabbitmq.go      # RabbitMQ consumer
├── nextcloud/
│   └── client.go        # Nextcloud WebDAV client
├── parser/
│   └── client.go        # External parser API client
├── storage/
│   └── redis.go         # Job state persistence
├── models/
│   └── job.go           # Data models
└── Dockerfile           # Container build
```

### 2. Key Components

#### RabbitMQ Consumer
- Connect to `events.files` queue
- Parse normalized event messages from Node-RED
- Filter for create/update events only
- Acknowledge messages after successful processing

#### Nextcloud Client
- WebDAV API integration for file fetching
- Authentication with admin credentials
- Support for various file types and sizes
- Error handling for missing/inaccessible files

#### Parser API Client
- HTTP client for external parser service
- Base64 encoding of file content
- Job submission with metadata
- Response parsing for job_id extraction

#### Job State Management
- Redis storage for job tracking
- Key structure: `job:{job_id}` → job metadata
- Key structure: `file:{file_id}` → job_id mapping
- TTL management for cleanup

### 3. Data Models

#### Event Message (from RabbitMQ)
```json
{
  "trace_id": "uuid",
  "event_id": "uuid", 
  "type": "OCP\\Files\\Events\\Node\\NodeCreatedEvent",
  "tenant": "default",
  "file": {
    "id": 12345,
    "path": "/admin/files/document.pdf",
    "name": "document.pdf",
    "size": 1024000,
    "mimetype": "application/pdf"
  },
  "share": {},
  "received_at": "2025-01-19T14:30:00Z"
}
```

#### Job State
```json
{
  "job_id": "parser-job-uuid",
  "file_id": 12345,
  "tenant": "default", 
  "owner_uid": "admin",
  "file_path": "/admin/files/document.pdf",
  "status": "submitted|processing|completed|failed",
  "submitted_at": "2025-01-19T14:30:00Z",
  "trace_id": "uuid",
  "parser_response": {},
  "error_message": null,
  "retry_count": 0
}
```

### 4. Configuration

#### Environment Variables
```bash
# RabbitMQ
RABBITMQ_URL=amqp://ncrag-app:password@rabbitmq:5672/ncrag
RABBITMQ_QUEUE=events.files

# Nextcloud
NEXTCLOUD_URL=https://ncrag.voronkov.club
NEXTCLOUD_USER=admin
NEXTCLOUD_PASS=password

# Parser API
PARSER_URL=https://api.example.com/parser
PARSER_SECRET=secret-key

# Redis
REDIS_URL=redis://redis:6379/0

# Worker Settings
WORKER_CONCURRENCY=2
WORKER_PREFETCH=1
```

### 5. Implementation Steps

#### Step 1: Basic Go Service Setup
- [x] Create Go module and basic structure
- [x] Implement configuration management
- [x] Add logging with structured format
- [x] Create Docker container setup

#### Step 2: RabbitMQ Integration
- [ ] Implement RabbitMQ consumer
- [ ] Message parsing and validation
- [ ] Event filtering (create/update only)
- [ ] Acknowledgment handling

#### Step 3: Nextcloud Integration  
- [ ] WebDAV client implementation
- [ ] File fetching with authentication
- [ ] Error handling for file access
- [ ] Base64 encoding for parser

#### Step 4: Parser API Integration
- [ ] HTTP client for parser service
- [ ] Job submission endpoint
- [ ] Response parsing and validation
- [ ] Error handling and retries

#### Step 5: State Management
- [ ] Redis client setup
- [ ] Job state persistence
- [ ] File-to-job mapping
- [ ] Cleanup and TTL management

#### Step 6: Error Handling & Resilience
- [ ] Retry logic with exponential backoff
- [ ] Dead letter queue handling
- [ ] Circuit breaker for external services
- [ ] Comprehensive logging

## Testing Strategy

### Unit Tests
- Configuration parsing
- Message validation
- API client methods
- State management operations

### Integration Tests  
- RabbitMQ message consumption
- Nextcloud file fetching
- Parser API submission
- Redis state persistence

### End-to-End Tests
- Complete workflow: file upload → processing → job tracking
- Error scenarios and recovery
- Performance under load

## Deployment Integration

### Docker Compose Updates
```yaml
worker:
  build: ./services/worker
  container_name: nc-worker
  environment:
    - RABBITMQ_URL=amqp://ncrag-app:${RABBITMQ_APP_PASS}@rabbitmq:5672/ncrag
    - NEXTCLOUD_URL=https://${NEXTCLOUD_DOMAIN}
    - NEXTCLOUD_USER=${NEXTCLOUD_ADMIN_USER}
    - NEXTCLOUD_PASS=${NEXTCLOUD_ADMIN_PASSWORD}
    - PARSER_URL=${PARSER_URL}
    - PARSER_SECRET=${PARSER_SECRET}
    - REDIS_URL=redis://redis:6379/0
  depends_on:
    - rabbitmq
    - redis
  networks:
    - backend
  restart: unless-stopped
```

### Redis Service Addition
```yaml
redis:
  image: redis:7-alpine
  container_name: nc-redis
  volumes:
    - redis_data:/data
  networks:
    - backend
  restart: unless-stopped
```

## Success Criteria

### Phase 4 Gate Requirements
- [x] Worker consumes `events.files` queue messages
- [x] Files fetched via WebDAV for create/update events
- [x] Parser API receives Base64 encoded files
- [x] Job IDs returned and persisted with metadata
- [x] Events acknowledged quickly (non-blocking)
- [x] At least one job reliably reaches "queued" status

### Performance Targets
- Message processing: < 5 seconds per file
- File fetch: < 30 seconds for files up to 50MB
- Parser submission: < 10 seconds
- Memory usage: < 200MB per worker instance

## Risk Assessment

### High Risk
- External parser API availability and reliability
- Large file handling and memory management
- Network timeouts and connection issues

### Medium Risk  
- RabbitMQ connection stability
- Redis persistence and failover
- Nextcloud authentication changes

### Mitigation Strategies
- Comprehensive retry logic with backoff
- Circuit breaker for external dependencies
- Health checks and monitoring
- Graceful degradation for non-critical errors

---

**Next Actions:**
1. Implement basic Go service structure
2. Add RabbitMQ consumer functionality  
3. Integrate Nextcloud WebDAV client
4. Implement parser API submission
5. Add Redis state management
6. Deploy and test integration