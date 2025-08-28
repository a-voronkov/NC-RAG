# NC-RAG
Experimental RAG replacement for NextCloud and Talk

## Docs

- Checklist: /docs/RAG-system-checklist.md
- Runbook: /docs/runbook.md
- APIs: /docs/apis
- Schemas: /docs/schemas
- Phase Reports: /docs/reports/phase-template.md

## Nextcloud customizations

- Custom Nextcloud image is built from `services/nextcloud/Dockerfile`.
- App `webhook_rabbitmq` is baked into the image and enabled via startup hook `services/nextcloud/hooks/10-config.sh`.
- Configure the plugin via env variables in `docker-compose.yml` (prefixed `NC_webhook_rabbitmq_...`).
