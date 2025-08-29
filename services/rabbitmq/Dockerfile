FROM rabbitmq:3-management

# Copy initialization scripts
COPY services/rabbitmq/init-rabbitmq.sh /usr/local/bin/init-rabbitmq.sh
COPY services/rabbitmq/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Make scripts executable
RUN chmod +x /usr/local/bin/init-rabbitmq.sh /usr/local/bin/docker-entrypoint.sh

# Use our custom entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
