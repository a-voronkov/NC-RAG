FROM nextcloud:31-apache

# Install PHP extensions for caching: redis, memcached, apcu
RUN set -eux; \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        php-redis \
        php-apcu \
        php-memcached \
        memcached && \
    rm -rf /var/lib/apt/lists/*

# Enable APCu for CLI and web
RUN { \
      echo "apc.enable_cli=1"; \
      echo "apc.enabled=1"; \
      echo "apc.shm_size=128M"; \
    } > /usr/local/etc/php/conf.d/apcu-custom.ini

# Provide default memcached config (can be overridden via env)
ENV MEMCACHED_HOST=memcached \
    MEMCACHED_PORT=11211

# Healthcheck to verify Nextcloud index is reachable internally
HEALTHCHECK --interval=30s --timeout=10s --retries=5 CMD curl -fsS http://localhost/index.php || exit 1