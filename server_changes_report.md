# Отчет о различиях между локальным репозиторием и сервером

## Обзор

На сервере `ncrag.voronkov.club` в папке `/srv/docker/nc-rag/` были обнаружены изменения, которые необходимо внести в репозиторий для корректного развертывания в будущем.

## Статус Git на сервере

```
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   docker-compose.yml
        modified:   scripts/register_webhooks.sh

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        services/node-red/settings.js
```

## Детальные изменения

### 1. docker-compose.yml

**Основные изменения:**

#### Traefik сервис:
- **Удалены переменные окружения** - заменены на хардкод значения:
  - `${LETSENCRYPT_EMAIL:-admin@voronkov.club}` → `admin@voronkov.club`
- **Изменен уровень логирования**: `DEBUG` → `INFO`
- **Удалены дополнительные настройки логирования**:
  - Убрана строка `--accesslog.filepath=/var/log/traefik/access.log`
- **Удалены HSTS middleware настройки**:
  - Убраны все labels с `traefik.http.middlewares.hsts.*`
- **Изменен формат портов**: `"80:80"` → `80:80` (убраны кавычки)

#### База данных (db):
- **Удалены переменные окружения** - заменены на хардкод:
  - `${POSTGRES_DB:-nextcloud}` → `nextcloud`
  - `${POSTGRES_USER:-nextcloud}` → `nextcloud`  
  - `${POSTGRES_PASSWORD:-nextcloudpass}` → `nextcloudpass`

#### Redis:
- **Изменен формат команды**: `["redis-server", "--appendonly", "no"]` → `redis-server --appendonly no`

#### Memcached:
- **Удалена настройка памяти**: убрана `command: ["-m", "128"]`

#### Nextcloud:
- **Понижена версия образа**: `nextcloud:31-apache` → `nextcloud:30-apache`
- **Удалена зависимость от traefik** в `depends_on`
- **Удалены переменные окружения** - заменены на хардкод:
  - Все `${POSTGRES_*}` переменные
  - `${NEXTCLOUD_ADMIN_USER:-admin}` → `admin`
  - `${NEXTCLOUD_ADMIN_PASSWORD:-adminpass}` → `j*yDCX<4ubIj_.w##>lhxDc?` (реальный пароль!)
  - `${NEXTCLOUD_TRUSTED_DOMAINS:-ncrag.voronkov.club}` → `ncrag.voronkov.club`
- **Изменены Traefik labels**:
  - Убран middleware `hsts`
  - Изменено правило роутинга: `/webhooks/nextcloud` → `/nodered`
  - Изменен приоритет: `100` → `1`

#### Nextcloud-cron:
- **Понижена версия образа**: `nextcloud:31-apache` → `nextcloud:30-apache`
- **Удалены переменные окружения** - заменены на хардкод

#### Node-RED:
- **Изменен способ сборки**: `build: context: ./services/node-red` → `image: nodered/node-red:4.1`
- **Удалены переменные окружения** - заменены на хардкод:
  - `${TENANT_DEFAULT:-default}` → `default`
  - `${WEBHOOK_SECRET:-change-me}` → `changeme`
- **Изменены volume mappings**:
  - Закомментирован: `#- ./services/node-red/flows.json:/data/flows.json`
  - Добавлен: `- ./services/node-red/settings.js:/data/settings.js`
- **Кардинально изменены Traefik labels**:
  - Добавлены два отдельных роутера: `nodered-webhook` и `nodered-ui`
  - Изменены пути: `/webhooks/nextcloud` → `/nodered/webhooks` и `/nodered`
  - Разные приоритеты: 1000 и 900

#### Удален сервис nc-webhook-seeder:
- Полностью удален сервис `nc-webhook-seeder` из конца файла

### 2. scripts/register_webhooks.sh

**Основные изменения:**

#### Исправление пути webhook:
- **Старый путь**: `uri="https://${NC_DOMAIN}/webhooks/nextcloud"`
- **Новый путь**: `uri="https://${NC_DOMAIN}/nodered/webhooks/nextcloud"`

#### Улучшения в логике:
- **Убрана идемпотентность**: удалена проверка существующих webhooks
- **Добавлены русские комментарии и эмодзи** для лучшей читаемости
- **Упрощена логика**: теперь всегда регистрирует события без проверки

#### Улучшенный вывод:
- Добавлены информативные сообщения о процессе регистрации
- Более понятный финальный вывод

### 3. Новый файл: services/node-red/settings.js

**Полностью новый файл** с настройками Node-RED:

```javascript
module.exports = {
    // Base URL path for Node-RED
    httpRoot: '/nodered',
    
    // UI settings  
    ui: { path: '/nodered/ui' },
    
    // Enable internal authentication
    adminAuth: {
        type: "credentials",
        users: [{
            username: "admin",
            password: "$2y$08$hUKXnOEmu9xHp48TbLdc2.7VqE1fhtxpwyW4/HRNupGn8Cikb23ta",
            permissions: "*"
        }]
    },
    
    // Other settings...
}
```

**Ключевые особенности:**
- Настройка базового пути `/nodered`
- Встроенная аутентификация с хешированным паролем
- Кастомизированный заголовок и URL

### 4. Отсутствующий файл: .env

На сервере создан `.env` файл с реальными значениями:
- Реальные пароли и секреты
- Конкретные URL и домены
- Настройки для всех сервисов

## Рекомендации по внесению изменений в репозиторий

### Критически важные изменения:

1. **Создать .env.example** с обновленной структурой переменных
2. **Добавить services/node-red/settings.js** в репозиторий
3. **Исправить пути в scripts/register_webhooks.sh**
4. **Обновить docker-compose.yml** с правильной конфигурацией Node-RED

### Изменения, требующие осторожности:

1. **Версии образов**: решить, использовать ли nextcloud:30 или 31
2. **Переменные окружения**: вернуть использование переменных вместо хардкода
3. **Traefik настройки**: восстановить HSTS и другие security headers
4. **Сервис nc-webhook-seeder**: решить, нужен ли он

### Безопасность:

⚠️ **ВНИМАНИЕ**: На сервере используются реальные пароли в открытом виде в docker-compose.yml. Необходимо:
1. Вернуть использование переменных окружения
2. Убедиться, что .env файл в .gitignore
3. Обновить пароли после внесения изменений

## Следующие шаги

1. Создать .env.example на основе серверного .env
2. Скопировать settings.js в репозиторий
3. Обновить docker-compose.yml с правильными путями Node-RED
4. Исправить register_webhooks.sh
5. Протестировать развертывание в тестовой среде