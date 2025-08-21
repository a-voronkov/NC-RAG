# Nextcloud Webhooks

## Endpoint

- POST `/webhooks/nextcloud`

## Auth

- Shared secret header (recommended) or IP allow-list via reverse proxy

## Delivery Semantics

- At-least-once. Consumers must deduplicate by `(event_id)`.

## Example Payload (normalized)

```json
{
  "trace_id": "<uuid>",
  "event_id": "<uuid>",
  "type": "node.created|node.updated|node.deleted|share.created|share.deleted",
  "tenant": "<tenant>",
  "file": {
    "file_id": "12345",
    "path": "/Documents/foo.pdf",
    "mtime": 1712345678,
    "owner_uid": "alice"
  },
  "share": {
    "scope": "user|group",
    "id": "<share_id>",
    "principal": "u:alice|g:staff"
  }
}
```

