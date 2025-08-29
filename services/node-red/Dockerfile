FROM nodered/node-red:4.1

# Install AMQP module for RabbitMQ integration
USER root
RUN npm install node-red-contrib-amqp

COPY flows.json /usr/src/node-red/flows_template.json

# Provide init entrypoint that seeds flows.json on first run
COPY --chown=root:root services/node-red/init-entrypoint.sh /usr/src/node-red/init-entrypoint.sh
RUN chmod +x /usr/src/node-red/init-entrypoint.sh

USER node-red
ENTRYPOINT ["/usr/src/node-red/init-entrypoint.sh"]