# Async Parser API

## Submit

- POST `${PARSER_URL}/parser/jobs`
- Headers: `Authorization: Bearer <token>` (if applicable)
- Content-Type: `multipart/form-data`
- Form fields:
  - `file`: uploaded file content
  - `trace_id` (optional): client-provided trace identifier

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
  "trace_id": "<uuid>",
  "status": "succeeded",
  "parser_version": "mock-1.0.0",
  "filename": "foo.pdf",
  "paragraphs": ["...", "..."],
  "raw_blocks_b64": ["..."],
  "qa": [ { "q": "...", "a": "...", "paragraph_index": 1 } ]
}
```

## Webhook

- POST `${PUBLIC_BASE_URL}/webhooks/parser`
- Headers: `X-Signature: hmac-sha256=...` (if configured)

```json
{ "trace_id": "<uuid>", "job_id": "<uuid>", "status": "succeeded|failed" }
```

