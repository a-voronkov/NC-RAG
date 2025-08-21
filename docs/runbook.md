# RAG System Runbook

This runbook provides operational procedures for the Nextcloud-driven, ACL-aware RAG platform.

## Contact and Ownership

- Primary owner: <fill>
- On-call rotation: <fill>
- Slack/Chat channel: <fill>

## Environments

- Single droplet: 4GB RAM, 2 vCPU, CPU-only
- Reverse proxy: Caddy/Traefik with TLS

## Services

- Nextcloud + PostgreSQL (Docker)
- Node-RED (webhook intake, message normalization)
- RabbitMQ (events/files, ingest/ready)
- Go workers (submitter, poller, webhook receiver, ingest)
- External parser (async REST + webhooks)
- Qdrant (vector database)
- RAG Query API (HTTP)

## Health Checks

- Nextcloud: `/status.php` returns installed:true
- Node-RED: `/admin` (if exposed) or `/admin/flows`
- RabbitMQ: Management API `/api/overview` (if exposed)
- Parser: `GET /health` or a simple auth-protected endpoint
- Qdrant: `GET /` returns version
- RAG API: `GET /healthz` returns OK

## Log Correlation and Trace IDs

- All components must include `trace_id` in structured JSON logs.
- Propagate `trace_id` from webhook → queue → workers → parser → ingest → query.

## Backups

- Nextcloud data volume: snapshot weekly
- PostgreSQL: daily dump
- Qdrant snapshots: daily

## Incident Response

1. Identify service impacted using dashboards (queue depth, job states, latency)
2. Collect logs for the relevant `trace_id`
3. Limit blast radius (pause consumers, increase backoff)
4. Remediate (restart components, drain/re-enqueue messages)
5. Postmortem within 48 hours

## Rate Limits

- Parser polling: ≤100 RPS (global). Use token bucket + backoff with jitter.
- Embeddings: configurable RPS; start low on 4GB droplet.

## Scaling Guidance

- Start single-threaded (`prefetch=1`).
- Increase one worker type at a time; watch memory and CPU.

## Security

- Never expose DB or AMQP to the public internet.
- Use HTTPS for all webhooks.
- Basic auth/IP allow-list for admin UIs.
- Zero secrets in logs.

## Playbooks

### Recover stuck jobs (parser)

1. Inspect job state in persistence store by `job_id`
2. If `submitted > 1h` and no webhook, let poller fetch and finalize
3. If poller disabled, enable temporarily with conservative RPS

### Rebuild file index

1. Delete Qdrant points by `file_id`
2. Re-submit file to parser via worker submitter

### Rotate credentials

1. Update `.env` and secrets store
2. Roll restart components
3. Verify health checks and test flows

## Appendix

- Env vars: see `.env.example`
- APIs: see `/docs/apis/*`
- Schemas: see `/docs/schemas/*`

