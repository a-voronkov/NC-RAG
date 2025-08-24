#!/bin/bash

# Инициализация flows.json если его нет
if [ ! -f /data/flows.json ]; then
    echo "Инициализация flows.json..."
    if [ -f /init/flows.json ]; then
        cp /init/flows.json /data/flows.json
        echo "flows.json скопирован из /init/"
    else
        # Создаем минимальный flows.json если исходного файла нет
        echo '[]' > /data/flows.json
        echo "Создан пустой flows.json"
    fi
    chown 1000:1000 /data/flows.json
    chmod 644 /data/flows.json
fi

# Запускаем оригинальный entrypoint Node-RED
exec /usr/src/node-red/docker-entrypoint.sh "$@"