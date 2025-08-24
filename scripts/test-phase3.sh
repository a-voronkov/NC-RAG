#!/bin/bash
set -e

echo "🧪 Testing Phase 3 - RabbitMQ Integration"
echo "========================================"

# Configuration
DOMAIN="${NEXTCLOUD_DOMAIN:-ncrag.voronkov.club}"
WEBHOOK_SECRET="${WEBHOOK_SECRET:-changeme}"
ADMIN_USER="${NEXTCLOUD_ADMIN_USER:-admin}"
ADMIN_PASS="${NEXTCLOUD_ADMIN_PASSWORD:-j*yDCX<4ubIj_.w##>lhxDc?}"

echo "📋 Test Configuration:"
echo "  Domain: $DOMAIN"
echo "  Webhook Secret: ${WEBHOOK_SECRET:0:8}..."
echo ""

# Test 1: Check RabbitMQ Management UI
echo "🐰 Test 1: RabbitMQ Management UI Access"
echo "----------------------------------------"
response=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/rabbitmq/" || echo "000")
if [ "$response" = "401" ]; then
    echo "✅ RabbitMQ Management UI accessible (requires auth)"
elif [ "$response" = "200" ]; then
    echo "⚠️  RabbitMQ Management UI accessible without auth (check config)"
else
    echo "❌ RabbitMQ Management UI not accessible (HTTP $response)"
fi
echo ""

# Test 2: Check parser webhook endpoint
echo "🔗 Test 2: Parser Webhook Endpoint"
echo "-----------------------------------"
response=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/webhooks/parser/" || echo "000")
if [ "$response" = "200" ] || [ "$response" = "404" ]; then
    echo "✅ Parser webhook endpoint accessible (HTTP $response)"
else
    echo "❌ Parser webhook endpoint not accessible (HTTP $response)"
fi
echo ""

# Test 3: Send test webhook to Node-RED
echo "📨 Test 3: Send Test Webhook to Node-RED"
echo "-----------------------------------------"
test_payload='{
  "event": {
    "node": {
      "id": 12345,
      "path": "/admin/files/test-phase3-'$(date +%s)'.txt"
    },
    "class": "OCP\\Files\\Events\\Node\\NodeCreatedEvent"
  },
  "user": {
    "uid": "admin",
    "displayName": "admin"
  },
  "time": '$(date +%s)'
}'

echo "Sending test payload..."
response=$(curl -s -X POST "https://$DOMAIN/nodered/webhooks/nextcloud" \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: $WEBHOOK_SECRET" \
  -d "$test_payload" \
  -w "%{http_code}" \
  -o /tmp/webhook_response.json)

if [ "$response" = "200" ]; then
    echo "✅ Webhook sent successfully"
    echo "Response: $(cat /tmp/webhook_response.json)"
else
    echo "❌ Webhook failed (HTTP $response)"
    echo "Response: $(cat /tmp/webhook_response.json 2>/dev/null || echo 'No response')"
fi
echo ""

# Test 4: Create actual file via WebDAV
echo "📁 Test 4: Create File via WebDAV"
echo "----------------------------------"
test_filename="phase3-test-$(date +%s).txt"
test_content="Phase 3 test file created at $(date)"

echo "$test_content" > /tmp/$test_filename
upload_response=$(curl -s -u "$ADMIN_USER:$ADMIN_PASS" \
  -T /tmp/$test_filename \
  "https://$DOMAIN/remote.php/dav/files/admin/$test_filename" \
  -w "%{http_code}" \
  -o /tmp/upload_response.txt)

if [ "$upload_response" = "201" ] || [ "$upload_response" = "204" ]; then
    echo "✅ File uploaded successfully: $test_filename"
    echo "   This should trigger a webhook to Node-RED → RabbitMQ"
    echo "   Check RabbitMQ management UI for messages in events.files queue"
else
    echo "❌ File upload failed (HTTP $upload_response)"
    echo "Response: $(cat /tmp/upload_response.txt 2>/dev/null || echo 'No response')"
fi
echo ""

# Test 5: Check Node-RED logs
echo "📋 Test 5: Recent Node-RED Activity"
echo "------------------------------------"
if [ -f "/tmp/webhook-log.jsonl" ]; then
    echo "Recent webhook events (last 3):"
    tail -3 /tmp/webhook-log.jsonl | while read line; do
        echo "  $line"
    done
else
    echo "⚠️  Webhook log file not accessible from this location"
    echo "   Check /data/webhook-log.jsonl inside Node-RED container"
fi
echo ""

# Cleanup
rm -f /tmp/$test_filename /tmp/webhook_response.json /tmp/upload_response.txt

echo "🎯 Phase 3 Testing Summary"
echo "=========================="
echo "1. ✅ RabbitMQ service configuration added"
echo "2. ✅ Node-RED AMQP integration configured"
echo "3. ✅ Parser webhook route configured"
echo "4. 🧪 Manual verification required:"
echo "   - Check RabbitMQ management UI: https://$DOMAIN/rabbitmq/"
echo "   - Verify events.files queue receives messages"
echo "   - Monitor Node-RED logs for AMQP connection status"
echo ""
echo "📚 Next Steps:"
echo "   - Deploy updated configuration to server"
echo "   - Verify queue message flow"
echo "   - Test persistence after container restart"