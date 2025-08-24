#!/bin/sh

# Проверяем, существует ли уже flows.json в томе
if [ ! -f /data/flows.json ]; then
    echo "flows.json не найден в томе, копируем начальную версию..."
    cp /init/flows.json /data/flows.json
    echo "flows.json успешно скопирован"
else
    echo "flows.json уже существует в томе, пропускаем копирование"
fi

# Убеждаемся, что права доступа корректны
chown -R 1000:1000 /data
chmod 644 /data/flows.json 2>/dev/null || true

echo "Инициализация завершена"