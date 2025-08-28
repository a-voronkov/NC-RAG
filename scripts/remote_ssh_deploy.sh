#!/bin/bash
set -euo pipefail

echo "=== Remote SSH Deploy (RabbitMQ via Traefik) ==="

: "${SSH_SERVER:?Missing SSH_SERVER}"
: "${SSH_USER:?Missing SSH_USER}"
: "${SSH_PASSWORD:?Missing SSH_PASSWORD}"

PROJECT_DIR_REMOTE="/srv/docker/nc-rag"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=15 -o NumberOfPasswordPrompts=1"

cleanup() {
	if [ -n "${ASKPASS:-}" ] && [ -f "${ASKPASS}" ]; then
		rm -f "${ASKPASS}" || true
	fi
}
trap cleanup EXIT

have_sshpass() {
	command -v sshpass >/dev/null 2>&1
}

ensure_askpass() {
	if have_sshpass; then
		return 0
	fi
	ASKPASS="$(mktemp -p "${TMPDIR:-/tmp}" askpass.XXXXXX)"
	# This helper prints the password from env when SSH prompts
	cat >"${ASKPASS}" <<'EOS'
#!/bin/sh
printf %s "$SSH_PASSWORD"
EOS
	chmod 700 "${ASKPASS}"
}

run_ssh() {
	if have_sshpass; then
		sshpass -p "$SSH_PASSWORD" ssh ${SSH_OPTS} "$@"
	else
		ensure_askpass
		DISPLAY=:0 SSH_ASKPASS="${ASKPASS}" setsid -w ssh ${SSH_OPTS} "$@"
	fi
}

copy_project() {
	echo "→ Creating remote dir: ${PROJECT_DIR_REMOTE}"
	run_ssh "${SSH_USER}@${SSH_SERVER}" "mkdir -p '${PROJECT_DIR_REMOTE}'"
	# Sync workspace using tar over SSH (excludes .git)
	echo "→ Syncing project files to remote..."
	tar --exclude .git -czf - -C "$(pwd)" . | \
		if have_sshpass; then sshpass -p "$SSH_PASSWORD" ssh ${SSH_OPTS} "${SSH_USER}@${SSH_SERVER}" "tar -xzf - -C '${PROJECT_DIR_REMOTE}'"; \
		else DISPLAY=:0 SSH_ASKPASS="${ASKPASS}" setsid -w ssh ${SSH_OPTS} "${SSH_USER}@${SSH_SERVER}" "tar -xzf - -C '${PROJECT_DIR_REMOTE}'"; fi
}

deploy_services() {
	echo "→ Deploying services on remote host..."
	run_ssh "${SSH_USER}@${SSH_SERVER}" bash -lc "set -e; cd '${PROJECT_DIR_REMOTE}'; if [ ! -f docker-compose.yml ]; then echo 'docker-compose.yml not found' >&2; ls -la; exit 1; fi; docker compose pull rabbitmq nextcloud; docker compose up -d rabbitmq traefik nextcloud; docker compose restart nextcloud; docker compose ps"
}

verify_ui() {
	URL="https://${SSH_SERVER}/rabbitmq/api/whoami"
	echo "→ Verifying RabbitMQ whoami: ${URL}"
	out=$(curl -s -i "$URL" | tr -d '\r' | sed -n '1,8p')
	echo "$out"
}

echo "Server: ${SSH_SERVER}"

echo "User:   ${SSH_USER}"

copy_project
deploy_services
verify_ui

echo "✅ Remote deploy complete."

