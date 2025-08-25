# Runbook

## Caches (Redis + Memcached) for Nextcloud

- Services added in `docker-compose.yml` on `backend` network:
  - `redis:7-alpine` as `nc-redis`
  - `memcached:1.6-alpine` as `nc-memcached`
- Nextcloud now uses a custom image `nc-custom-nextcloud:31-apache` with `php-redis`, `php-apcu`, and `php-memcached` installed.

### Nextcloud memcache configuration

Recommended config in `config/config.php` (set via occ after deploy):

```php
'memcache.local' => '\\OC\\Memcache\\APCu',
'memcache.distributed' => '\\OC\\Memcache\\Redis',
'memcache.locking' => '\\OC\\Memcache\\Redis',
'redis' => [
  'host' => 'redis',
  'port' => 6379,
  'dbindex' => 0,
  'password' => '',
  'timeout' => 1.5,
],
```

Apply via occ inside container:

```bash
docker exec -u www-data nextcloud php occ config:system:set memcache.local --value='\OC\Memcache\APCu'
docker exec -u www-data nextcloud php occ config:system:set memcache.distributed --value='\OC\Memcache\Redis'
docker exec -u www-data nextcloud php occ config:system:set memcache.locking --value='\OC\Memcache\Redis'
docker exec -u www-data nextcloud php occ config:system:set redis host --value=redis
docker exec -u www-data nextcloud php occ config:system:set redis port --value=6379 --type=integer
```

### Rebuild & restart

```bash
# From project root
docker compose build nextcloud nextcloud-cron
docker compose up -d --remove-orphans
```

### Verify Talk and bot user

```bash
docker compose exec nextcloud bash -lc "php occ app:list | grep spreed || true"
docker compose exec nextcloud bash -lc "php occ user:info ${NEXTCLOUD_BOT_USER:-bot} || true"
```