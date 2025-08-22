# Nextcloud Webhooks

## Endpoint

- POST `/webhooks/nextcloud`

## Auth

- Shared secret header `X-Webhook-Secret` (recommended) or IP allow-list via reverse proxy

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

## Nextcloud Setup

- Install and enable WebhookListeners app.
- Add endpoint URL: `https://<domain>/webhooks/nextcloud`.
- Add header: `X-Webhook-Secret: <value>` matching `WEBHOOK_SECRET`.
- Select events: node created/updated/deleted, share created/deleted.

