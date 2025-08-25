#!/bin/sh
set -euf
BASE="https://${NC_DOMAIN}/ocs/v2.php/apps/webhook_listeners/api/v1/webhooks"
AUTH="${NC_ADMIN_USER}:${NC_ADMIN_PASS}"
HDR1="OCS-APIRequest: true"
HDR2="Accept: application/json"

# CORRECTED PATH: /nodered/webhooks/nextcloud
uri="https://${NC_DOMAIN}/nodered/webhooks/nextcloud"
post_evt() {
  evt="$1"
  curl -sk -u "$AUTH" -H "$HDR1" -H "$HDR2" -X POST "$BASE" \
    --data-urlencode "httpMethod=POST" \
    --data-urlencode "uri=${uri}" \
    --data-urlencode "event=${evt}" \
    --data-urlencode "userIdFilter=" \
    --data-urlencode "headers[Content-Type]=application/json" \
    --data-urlencode "authMethod=header" \
    --data-urlencode "authData[X-Webhook-Secret]=${WEBHOOK_SECRET}"
}

echo "🔄 Registering webhooks with correct path: $uri"

# Register Files and Share events
for E in \
  "OCP\\Files\\Events\\Node\\NodeCreatedEvent" \
  "OCP\\Files\\Events\\Node\\NodeUpdatedEvent" \
  "OCP\\Files\\Events\\Node\\NodeDeletedEvent" \
  "OCP\\Share\\Events\\ShareCreatedEvent" \
  "OCP\\Share\\Events\\ShareDeletedEvent"; do
  echo "📝 Registering: $E"
  post_evt "$E" || true
done

# Attempt to register Talk events (best-effort; class names may vary by version)
for E in \
  "OCA\\Talk\\Events\\MessageSentEvent" \
  "OCA\\Talk\\Events\\ConversationCreatedEvent" \
  "OCA\\Talk\\Events\\ParticipantAddedEvent"; do
  echo "📝 Registering (Talk): $E"
  post_evt "$E" || true
done

echo ""
echo "✅ Final webhook list:"
curl -sk -u "$AUTH" -H "$HDR1" -H "$HDR2" "${BASE}?format=json" | sed -n '1,200p'
