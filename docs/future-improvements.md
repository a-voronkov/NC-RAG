# Future Improvements

## Real-time Webhook Delivery

**Current State:** Webhooks are processed via Nextcloud cron job, causing delays up to 60 seconds.

**Problem:** The delay between file operations and webhook delivery affects user experience and real-time processing capabilities.

**Proposed Solutions:**

### Option 1: Nextcloud Background Jobs Optimization
- Configure Nextcloud to use `cron` instead of `ajax` for background jobs
- Reduce cron interval from default 5 minutes to 1 minute or less
- Enable `occ background:cron` with higher frequency

### Option 2: Flow App Integration
- Install and configure Nextcloud Flow app
- Create flows that trigger on file events
- Use Flow's HTTP request action to call webhooks directly
- Potentially provides near real-time delivery

### Option 3: Custom Nextcloud App
- Develop a minimal Nextcloud app that hooks into file events
- Use Nextcloud's event dispatcher to catch events immediately
- Send HTTP requests to webhook endpoints synchronously
- Requires PHP development and app installation

### Option 4: Database Polling
- Monitor Nextcloud database for activity table changes
- Use external service to poll for new file operations
- Transform database events into webhook calls
- Requires database access and careful monitoring

### Recommended Approach

**Phase 1:** Try Flow app integration (Option 2)
- Minimal development effort
- Uses existing Nextcloud infrastructure
- Can be configured through UI

**Phase 2:** If Flow doesn't provide sufficient real-time performance, consider custom app (Option 3)

### Implementation Priority

- **Priority:** Medium (after core RAG functionality is complete)
- **Estimated Effort:** 1-2 days for Flow integration, 1-2 weeks for custom app
- **Dependencies:** Core system must be stable and functional
- **Testing:** Measure actual delivery times and compare with current cron-based approach

## Other Future Improvements

### Performance Optimizations
- Implement connection pooling for database connections
- Add Redis caching for frequently accessed data
- Optimize vector search queries in Qdrant

### Monitoring & Observability
- Add Prometheus metrics collection
- Implement structured logging with correlation IDs
- Create Grafana dashboards for system health

### Security Enhancements
- Implement API rate limiting
- Add audit logging for all operations
- Regular security updates and vulnerability scanning

### Scalability Improvements
- Horizontal scaling for worker processes
- Load balancing for multiple Node-RED instances
- Database read replicas for query performance