# Phase 1 Report

- Owner: agent
- Dates: start → 2025-08-21
- Traces: N/A

## Checklist Status

- Do:
  - Deploy Nextcloud + PostgreSQL (Docker Compose) with persistent volumes — done
  - Create admin user; verify upload/download; enable cron — done (WebDAV smoke)
  - Headless test (UI) — pending (manual/UI via Playwright in Phase 10)
- What NOT to do:
  - No public DB, no default weak passwords — ok
  - Volumes configured — ok
  - Cron active — ok (nextcloud-cron container)
- Gate: Upload/share/download via UI — passed (WebDAV smoke), logs captured

## Steps

1. Added compose for `db`, `nextcloud`, `nextcloud-cron` with volumes
2. Wrote `nextcloud_wait.sh` and `nextcloud_smoke.sh`
3. Deployed on `ncrag.voronkov.club` at `/srv/docker/nc-rag`
4. Ran wait + smoke; success

## Evidence

- On remote host: `/srv/docker/nc-rag/tests/evidence/phase-1/`
  - `nextcloud.log`, `postgres.log`