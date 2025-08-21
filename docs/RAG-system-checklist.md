# RAG System Implementation Checklist (with Anti-Patterns)

Goal: Build a Nextcloud-driven, ACL-aware RAG system on a 4GB / 2 vCPU droplet (CPU-only), with Node-RED, RabbitMQ, Go workers, external parser (async REST+webhooks), Qdrant, and a RAG API.

Global rules (apply to all phases):

- Document everything (`/docs/reports/phase-<N>.md`, `/docs/runbook.md`, `/docs/apis/*.md`, `/docs/schemas/*.json`).
- Add trace IDs to logs and propagate across steps.
- Use headless tests (Playwright) to verify user-visible flows.
- Do not proceed to next phase until the prior Gate passes.

---

## Phase 1 — Base System (Nextcloud + DB)

Do

- [ ] Deploy Nextcloud + PostgreSQL (Docker Compose) with persistent volumes.
- [ ] Create admin user; verify upload/download; enable cron/background jobs.
- [ ] Headless test: login → upload small file → download → assert contents.

What NOT to do

- [ ] Don’t run without volumes (data loss on restart).
- [ ] Don’t expose DB publicly; don’t reuse weak/default passwords.
- [ ] Don’t continue if uploads fail or cron is not active.

Gate

- [ ] Upload/share/download work via UI. Logs show no startup errors.

---

## Phase 2 — Webhooks (Nextcloud → Node-RED)

Do

- [ ] Enable WebhookListeners (and Flow if needed for share events).
- [ ] Register HTTPS endpoint(s): POST `/webhooks/nextcloud`.
- [ ] In Node-RED, parse payload → normalize JSON for queueing.

What NOT to do

- [ ] Don’t process files inside Node-RED (no heavy work here).
- [ ] Don’t leave webhook delivery on 5-min cron; enable faster worker mode.
- [ ] Don’t expose Node-RED editor publicly without auth.

Verify

- [ ] Simulate upload/delete/share; see Node-RED receive events quickly.

Gate

- [ ] All required event types are received and logged within ~60s.

---

## Phase 3 — Queue Layer (RabbitMQ)

Do

- [ ] Deploy RabbitMQ (`amqp://…`), enable management UI (internal).
- [ ] Declare queues: `events.files`, `ingest.ready` (or similar).
- [ ] Wire Node-RED → `events.files`.

What NOT to do

- [ ] Don’t publish large binaries to the queue (no base64 in AMQP).
- [ ] Don’t leave `guest/guest` or expose AMQP port to the internet.
- [ ] Don’t skip confirm/ack checks in basic test.

Verify

- [ ] File upload → message visible in `events.files`.

Gate

- [ ] Messages reliably appear for create/update/delete/share.

---

## Phase 3b — HTTPS Fronting (Reverse Proxy)

Do

- [ ] Run Caddy/Traefik with Let’s Encrypt.
- [ ] Routes:
  - `/webhooks/nextcloud` → Node-RED
  - `/webhooks/parser` → worker/receiver
- [ ] Protect admin UIs (basic auth/IP allow-list).

What NOT to do

- [ ] Don’t accept parser webhooks over HTTP; must be HTTPS.
- [ ] Don’t expose RabbitMQ UI broadly.

Gate

- [ ] `curl -I https://<domain>/webhooks/parser` returns expected 200/401; valid TLS.

---

## Phase 4 — Worker (Go) — Submit to Async Parser

Do

- [ ] Consume `events.files`; for create/update:
- [ ] Fetch file via WebDAV/API.
- [ ] Base64 encode; `POST /parser/jobs` → get `job_id`.
- [ ] Persist `job_id` ↔ `file_id`, tenant, owner (Redis/DB).
- [ ] Ack event quickly.
- [ ] Log `trace_id`, `job_id`, `file_id`.

What NOT to do

- [ ] Don’t block waiting for parse completion on the event consumer.
- [ ] Don’t send raw files through RabbitMQ.
- [ ] Don’t store secrets/tokens in logs.

Verify

- [ ] Submit file → parser returns `job_id`; job state saved.

Gate

- [ ] At least one job reliably reaches queued.

---

## Phase 5 — Parser Completion (Polling + Webhook)

Do

- [ ] Webhook receiver `POST /webhooks/parser`:
  - [ ] Validate secret/HMAC if available.
  - [ ] On finished → publish `{job_id}` to `ingest.ready`.
  - [ ] On failed → mark failed.
- [ ] Poller (respect ≤100 RPS):
  - [ ] Token bucket limiter + backoff (2s→4s→8s…max 30s, jitter).
  - [ ] `GET /jobs/<id>/status`; on ready: `GET /jobs/<id>/result` → enqueue `ingest.ready`.
  - [ ] Deduplicate if webhook already delivered.

What NOT to do

- [ ] Don’t exceed parser’s 100 RPS (global).
- [ ] Don’t keep polling after webhook success.
- [ ] Don’t crash on parser/network 5xx; retry with backoff.

Verify

- [ ] Webhook path: receives status change, emits exactly one `ingest.ready`.
- [ ] Polling path: recovers from transient failures.

Gate

- [ ] One job completes via webhook path and one via polling path (in tests).

---

## Phase 6 — Ingest (Embeddings + Qdrant Upsert)

Do

- [ ] Consume `ingest.ready {job_id}`.
- [ ] Build points:
  - [ ] `chunks[]` → `type="chunk"`, `chunk_id`, `text`, `page`.
  - [ ] `qa[]`     → `type="qa"`, `q`, `a`.
  - [ ] Named vectors: `chunk_vec` for chunks, `qa_vec` for Q&A (fill only relevant).
- [ ] ACL payload:
  - [ ] `tenant`, `file_id`, `owner_uid`
  - [ ] `principals: ["u:<owner>", "g:<group>…"]` (owner only at first)
  - [ ] `path?`, `mtime?`, `embed_model`, `parser_version`.
- [ ] Embeddings via Ollama (Basic Auth) or local CPU model; batch 16–64 texts.
- [ ] Qdrant upsert with `wait=true` (single batched call).

What NOT to do

- [ ] Don’t hardcode model name; read from env.
- [ ] Don’t store huge payloads; keep text reasonable per point.
- [ ] Don’t mix vector dimensions across named vectors.

Verify

- [ ] Random point has correct type, vector size, and ACL fields.
- [ ] Search by a known phrase returns that chunk.

Gate

- [ ] Full file → vectors (chunks+Q&A) present and searchable.

---

## Phase 7 — Deletions

Do

- [ ] On NodeDeletedEvent (file): Qdrant delete by `file_id` filter.
- [ ] On folder delete: rely on per-file events; log folder-only events.

What NOT to do

- [ ] Don’t delete by filename alone (non-unique).
- [ ] Don’t leave stale points after delete.

Verify

- [ ] After delete event, `file_id` points absent in Qdrant.

Gate

- [ ] Deletion removes all points reliably.

---

## Phase 8 — Sharing / ACL Updates

Do

- [ ] On share granted:
  - [ ] If to user: merge `principals += ["u:<uid>"]`.
  - [ ] If to group: merge `principals += ["g:<gid>"]`.
  - [ ] Implement merge: read current payload (one point), compute set union, update all points by `file_id` filter.
- [ ] On share revoked: remove from set and update.

What NOT to do

- [ ] Don’t re-embed/re-parse on ACL changes.
- [ ] Don’t overwrite principals blindly (must merge).
- [ ] Don’t encode group members as users (store groups as `g:<gid>`).

Verify

- [ ] After grant: filter by principals includes new user/group.
- [ ] After revoke: user/group no longer matches.

Gate

- [ ] ACL changes reflected in Qdrant within seconds.

---

## Phase 9 — RAG Query Service

Do

- [ ] `/query` accepts `{user_id, query}`.
- [ ] Resolve user groups via Nextcloud OCS; build set `A = {"u:<uid>"} ∪ {"g:<gid>…"}`.
- [ ] Generate query embedding (Ollama or local).
- [ ] Dual search:
  - [ ] `chunk_vec` top K1 with filter: `tenant` AND `principals ∩ A`
  - [ ] `qa_vec` top K2 with same filter
- [ ] Fuse (RRF) → optional rerank (CPU cross-encoder or BM25).
- [ ] Return `{answer?, snippets, sources[]}`:
  - [ ] Option A (recommended initially): call OpenAI for answer synthesis using retrieved context (if allowed).
  - [ ] Option B (privacy-strict): return extractive snippets; add local LLM later.

What NOT to do

- [ ] Don’t bypass ACL filter.
- [ ] Don’t feed excessive context; cap tokens/snippets.
- [ ] Don’t send sensitive data to external LLMs unless approved.

Verify

- [ ] “Found” case: correct answer/snippets citing right file(s).
- [ ] “Unauthorized” case: zero leakage across users.
- [ ] “Not found” case: clear fallback message (use score threshold).

Gate

- [ ] All three scenarios pass within acceptable latency (OpenAI: ~2–8s p95; local LLM may be slower).

---

## Phase 10 — Headless E2E (Playwright)

Do

- [ ] Scenarios:
  - [ ] Nextcloud smoke: login/upload/download.
  - [ ] Node-RED health: `/admin` (if exposed) or `/admin/flows` API.
  - [ ] RabbitMQ: queue presence via management API (if exposed).
  - [ ] Webhook delivery: upload → event seen in queue.
  - [ ] Parser lifecycle: submitted → processing → finished (via `/webhooks/parser` or poll).
  - [ ] RAG query: correct answer/snippets & sources.

What NOT to do

- [ ] Don’t exceed parser polling limits in tests.
- [ ] Don’t run many parallel workers on the small droplet (set Playwright `workers=1`).

Gate

- [ ] `npm run test:e2e` passes and artifacts saved to `/tests/evidence/`.

---

## Phase 11 — Resilience, Limits, Observability

Do

- [ ] Global rate limiters (parser polling ≤100 RPS; embeddings RPS configurable).
- [ ] Exponential backoff + jitter; circuit breaker on 5xx.
- [ ] Metrics: queue depth, job states, ingest counts, query latency.
- [ ] Structured logs (JSON) with `trace_id`.

What NOT to do

- [ ] Don’t parallelize ingest beyond CPU budget (start with `prefetch=1`).
- [ ] Don’t log secrets or full document contents.

Gate

- [ ] Load test (10 files) respects limits; no deadlocks; memory stable.

---

## Final Acceptance

- [ ] All phases have reports & checklists completed and committed.
- [ ] Multilingual: same doc in non-EN retrieved & answered correctly.
- [ ] ACL: cross-user leakage = 0 in tests.
- [ ] CPU-only: no GPU dependencies; system stable on 4GB/2vCPU.
- [ ] Full lifecycle: create/update/share/unshare/delete reflected in index within ~1 min.

---

## Minimal Env Vars (recap)

```
NEXTCLOUD_URL, NEXTCLOUD_USER, NEXTCLOUD_PASS
RABBITMQ_URL
QDRANT_URL
PARSER_URL, PARSER_SECRET
PUBLIC_BASE_URL  # for HTTPS webhooks
OLLAMA_URL, OLLAMA_BASIC_AUTH, OLLAMA_EMBED_MODEL
TENANT_DEFAULT
```

