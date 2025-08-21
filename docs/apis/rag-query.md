# RAG Query API

## POST `/query`

### Request

```json
{ "user_id": "alice", "query": "How to reset password?", "tenant": "default" }
```

### Steps

1. Resolve user groups via Nextcloud OCS
2. Generate embedding
3. Dual search `chunk_vec` and `qa_vec` with ACL filter
4. Fuse and optionally rerank

### Response (extractive)

```json
{
  "trace_id": "<uuid>",
  "snippets": [
    { "text": "...", "score": 0.71, "file_id": "12345", "path": "/Docs/a.pdf" }
  ],
  "sources": [ { "file_id": "12345", "path": "/Docs/a.pdf" } ]
}
```

### Response (generative)

```json
{ "trace_id": "<uuid>", "answer": "...", "snippets": [ ... ], "sources": [ ... ] }
```

