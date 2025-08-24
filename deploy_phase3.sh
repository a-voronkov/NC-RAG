#!/bin/bash

set -e

echo "=== Развертывание Фазы 3 на сервере ==="

# Проверяем переменные окружения
if [[ -z "$SSH_SERVER" || -z "$SSH_USER" || -z "$SSH_PASSWORD" ]]; then
    echo "Ошибка: Не заданы переменные SSH_SERVER, SSH_USER, SSH_PASSWORD"
    exit 1
fi

echo "Сервер: $SSH_SERVER"
echo "Пользователь: $SSH_USER"

# Функция для выполнения команд на сервере
run_remote() {
    local cmd="$1"
    echo "Выполняю на сервере: $cmd"
    
    # Используем heredoc для передачи команд
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$SSH_USER@$SSH_SERVER" << EOF
cd /srv/docker/nc-rag
$cmd
EOF
}

# Проверяем подключение
echo "Проверяю подключение к серверу..."
run_remote "pwd && whoami"

# Проверяем текущее состояние
echo "Проверяю текущее состояние проекта..."
run_remote "ls -la && git status"

# Синхронизируем изменения
echo "Синхронизирую изменения с локальным репозиторием..."
rsync -avz --exclude='.git' ./ "$SSH_USER@$SSH_SERVER:/srv/docker/nc-rag/"

# Проверяем изменения
echo "Проверяю изменения после синхронизации..."
run_remote "git status && git diff --name-only"

# Развертываем обновления
echo "Развертываю обновления..."
run_remote "docker compose down && docker compose build --no-cache node-red && docker compose up -d"

# Проверяем статус сервисов
echo "Проверяю статус сервисов..."
run_remote "docker compose ps"

echo "=== Развертывание завершено ==="