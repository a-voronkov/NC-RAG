FROM nextcloud:31-apache
COPY hooks/10-config.sh /docker-entrypoint-hooks.d/before-starting/10-config.sh
COPY zzzz-session.ini /usr/local/etc/php/conf.d/zzzz-session.ini
RUN chmod +x /docker-entrypoint-hooks.d/before-starting/10-config.sh
