FROM nextcloud:31-apache

# Install php-amqp extension required by the webhook_rabbitmq app
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends pkg-config libssl-dev librabbitmq-dev autoconf build-essential git; \
    pecl install amqp; \
    docker-php-ext-enable amqp; \
    apt-get purge -y --auto-remove git autoconf build-essential pkg-config; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy startup hook to enable and configure custom apps before Apache starts
COPY services/nextcloud/hooks/10-config.sh /docker-entrypoint-hooks.d/before-starting/10-config.sh
RUN chmod +x /docker-entrypoint-hooks.d/before-starting/10-config.sh

# Bake the webhook_rabbitmq Nextcloud app into the image so it is always present
# Use /usr/src/nextcloud/custom_apps so it is copied into the persistent volume on first run
COPY --chown=www-data:www-data webhook_rabbitmq /usr/src/nextcloud/custom_apps/webhook_rabbitmq

# PHP session tuning
COPY services/nextcloud/zzzz-session.ini /usr/local/etc/php/conf.d/zzzz-session.ini
