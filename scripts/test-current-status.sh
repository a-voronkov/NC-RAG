#!/bin/bash

echo "🔍 NC-RAG Current Status Check"
echo "=============================="

DOMAIN="ncrag.voronkov.club"

echo "📊 Service Status:"
echo "- Nextcloud: $(curl -s -o /dev/null -w '%{http_code}' https://$DOMAIN/)"
echo "- RabbitMQ: $(curl -s -o /dev/null -w '%{http_code}' https://$DOMAIN/rabbitmq/)"
echo "- Node-RED: $(curl -s -o /dev/null -w '%{http_code}' https://$DOMAIN/nodered/)"
echo "- Parser: $(curl -s -o /dev/null -w '%{http_code}' https://$DOMAIN/webhooks/parser/)"
echo ""

echo "🧪 Testing Webhook Endpoint:"
webhook_status=$(curl -s -X POST "https://$DOMAIN/nodered/webhooks/nextcloud" \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: changeme" \
  -d '{"test": "webhook"}' \
  -w '%{http_code}' -o /tmp/webhook_test.txt)

echo "Webhook response: $webhook_status"
if [ -f /tmp/webhook_test.txt ]; then
    echo "Response body: $(cat /tmp/webhook_test.txt)"
    rm -f /tmp/webhook_test.txt
fi
echo ""

echo "📋 Deployment Status:"
if [ "$webhook_status" = "200" ]; then
    echo "✅ Phase 2/3 appears deployed (Node-RED responding)"
else
    echo "❌ Phase 2/3 needs deployment (Node-RED not responding)"
fi

parser_status=$(curl -s -o /dev/null -w '%{http_code}' https://$DOMAIN/webhooks/parser/health)
if [ "$parser_status" = "200" ]; then
    echo "✅ Phase 4 appears deployed (Parser responding)"
else
    echo "❌ Phase 4 needs deployment (Parser not responding)"
fi
echo ""

echo "🚀 Next Steps:"
echo "1. SSH to server: ssh root@$DOMAIN"
echo "2. Check docker status: docker compose ps"
echo "3. Deploy missing phases: docker compose up -d --build"
echo "4. Test integration: ./scripts/test-phase4.sh"