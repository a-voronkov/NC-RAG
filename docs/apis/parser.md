# Async Parser API

## Submit

- POST `${PARSER_URL}/parser/jobs`
- Headers: `Authorization: Bearer <token>` (if applicable)
- Body:

```json
{
  "trace_id": "<uuid>",
  "filename": "foo.pdf",
  "content_base64": "...",
  "options": { "language": "auto" }
}
```

### Response

```json
{ "job_id": "<uuid>" }
```

## Status

- GET `${PARSER_URL}/jobs/{job_id}/status`

```json
{ "job_id": "<uuid>", "status": "queued|processing|succeeded|failed" }
``;

## Result

- GET `${PARSER_URL}/jobs/{job_id}/result`

```json
{
  "job_id": "<uuid>",
  "chunks": [ { "chunk_id": "c1", "text": "...", "page": 1 } ],
  "qa": [ { "q": "...", "a": "..." } ],
  "parser_version": "v1.2.3"
}
```

## Webhook

- POST `${PUBLIC_BASE_URL}/webhooks/parser`
- Headers: `X-Signature: hmac-sha256=...` (if configured)

```json
{ "trace_id": "<uuid>", "job_id": "<uuid>", "status": "succeeded|failed" }
```

