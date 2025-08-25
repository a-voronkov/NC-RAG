# Nextcloud Talk Bot (@bot) - Design and Implementation

## Goals

- Service user `@bot` visible in user list and DM-able at any time
- Present in all required Talk conversations (existing and new)
- Ability to receive messages and respond in DMs and group rooms
- Repeatable, automated provisioning as part of base image and deployment

## High-level Architecture

- Preprovisioned Nextcloud user (service account): `bot`
- Talk app (`spreed`) installed and enabled automatically in custom image hook
- WebhookListeners app delivers file/share events today; we also attempt to subscribe to Talk events
- Bot runtime (options):
  - Minimal: command-based responders via `occ talk:command:add` (shell scripts)
  - Advanced: external bot service using Talk OCS API or community frameworks
    - Python: `nextcloud-talk-bot` (wraps OCS, supports NLP)
    - gRPC: `nextcloud-talk-bot-framework` (polyglot)
    - Official app-based: `talk_bot_ai` (AppAPI + Talk Bot API)

## Provisioning Flow (Automated)

1) Custom Nextcloud image
   - `services/nextcloud/Dockerfile` now copies `/docker-entrypoint-hooks.d/before-starting/10-config.sh`
   - Hook script ensures `spreed` is enabled and creates `@bot` if env vars set
   - Compose switched to build this image and use it for `nextcloud` and `nextcloud-cron`

2) Environment variables
   - `NEXTCLOUD_BOT_USER=bot`
   - `NEXTCLOUD_BOT_PASSWORD=<secure>`
   - `NEXTCLOUD_BOT_DISPLAY_NAME=Service Bot`

3) Webhooks
   - `scripts/register_webhooks.sh` registers Files/Share events
   - Best-effort registration for Talk events (if supported):
     - `OCA\\Talk\\Events\\MessageSentEvent`
     - `OCA\\Talk\\Events\\ConversationCreatedEvent`
     - `OCA\\Talk\\Events\\ParticipantAddedEvent`

Note: Talk event classes may differ between versions; verify in server logs or app code and adjust.

## Bot Interaction Approaches

- Commands (lightweight):
  - Register commands that users can invoke: `/help`, `/ping`, etc.
  - Each command triggers a script with context placeholders: `{ARGUMENTS} {ROOM} {USER}`
  - Example (to be integrated later):
    - `occ talk:command:add ping "Ping bot" "/usr/local/bin/bot_ping.sh {ROOM} {USER}" 0 0`

- External service (recommended for rich logic):
  - Auth with `@bot` credentials
  - Use OCS Talk API to:
    - List conversations, join/add participant (where allowed)
    - Poll or receive events and send messages
  - Frameworks:
    - Python `nextcloud-talk-bot`: simplifies OCS calls, examples available
    - gRPC framework: language-agnostic bots

## Practical Steps to Have @bot Everywhere

1) Pre-create `@bot` (done by hook if vars provided)
2) Add to existing rooms:
   - Manually via UI initially, or
   - Script using OCS API with admin or `@bot` (if permitted) to add participant to each conversation
3) Auto-join new rooms:
   - Periodic job that lists new rooms and adds `@bot`
   - Or register server-side automation once Talk provides stable hooks for this

Limitations: Nextcloud Talk does not currently offer a single "global participant" flag; presence must be managed per room.

## OCS API (Reference Pointers)

While official docs are sparse, commonly used endpoints follow this pattern:

- Base: `/ocs/v2.php/apps/spreed/api/v4/` (OCS headers required: `OCS-APIRequest: true`)
- Examples used by community clients:
  - `GET rooms`
  - `POST rooms/<token>/message`
  - `POST rooms/<token>/participants` (add user)

Consult your server's `/ocs/v2.php/apps/spreed/api/` for discoverability and cross-check with framework source.

## Deployment Changes in This Repo

- Compose now builds `ncrag-nextcloud:31-apache` from `services/nextcloud/`
- Hook script `services/nextcloud/hooks/10-config.sh` provisions Talk and `@bot`
- Webhook registration extended with best-effort Talk events

## Operations

- Rotate `NEXTCLOUD_BOT_PASSWORD` via `.env` and re-deploy
- Verify `spreed` enabled: `occ app:list | grep spreed`
- Verify bot user: `occ user:info bot`
- Test DM to `bot` and posting in a room with `bot` as participant

## Next Steps (optional)

- Implement an external bot microservice using Python `nextcloud-talk-bot`
- Register useful Talk commands (`occ talk:command:add ...`)
- Add a scheduled job to auto-join `@bot` to new rooms

