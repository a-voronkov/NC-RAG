#!/bin/bash

set -e

echo "=== Развертывание Фазы 3 через архив ==="

# Создаем архив с изменениями
echo "📦 Создаю архив с изменениями Фазы 3..."
tar -czf phase3-deployment.tar.gz \
    docker-compose.yml \
    .env.example \
    services/node-red/ \
    scripts/rabbitmq-init.sh \
    scripts/test-phase3.sh \
    docs/reports/phase-3-deployment-plan.md

echo "✅ Архив создан: phase3-deployment.tar.gz"
ls -lh phase3-deployment.tar.gz

echo ""
echo "📋 Инструкции для развертывания на сервере:"
echo "1. Скопируйте архив на сервер:"
echo "   scp phase3-deployment.tar.gz root@ncrag.voronkov.club:/srv/docker/nc-rag/"
echo ""
echo "2. Подключитесь к серверу:"
echo "   ssh root@ncrag.voronkov.club"
echo ""
echo "3. Перейдите в папку проекта и разверните архив:"
echo "   cd /srv/docker/nc-rag"
echo "   tar -xzf phase3-deployment.tar.gz"
echo ""
echo "4. Создайте .env файл:"
echo "   cp .env.example .env"
echo "   nano .env  # Отредактируйте с реальными значениями"
echo ""
echo "5. Разверните обновления:"
echo "   docker compose down"
echo "   docker compose build --no-cache node-red"
echo "   docker compose up -d"
echo ""
echo "6. Проверьте развертывание:"
echo "   docker compose ps"
echo "   ./scripts/test-phase3.sh"
echo ""
echo "7. Проверьте RabbitMQ Management UI:"
echo "   https://ncrag.voronkov.club/rabbitmq/ (admin/admin)"
echo ""

echo "🎯 Архив готов для развертывания!"