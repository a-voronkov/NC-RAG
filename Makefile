SHELL := /usr/bin/bash

.PHONY: up down logs nc-wait nc-smoke phase1

up:
	docker compose up -d --build db nextcloud nextcloud-cron

down:
	docker compose down -v

logs:
	docker compose logs -f --tail=200 nextcloud db

nc-wait:
	./scripts/nextcloud_wait.sh

nc-smoke:
	./scripts/nextcloud_smoke.sh

phase1: up nc-wait nc-smoke
	@echo "Phase 1 OK"

