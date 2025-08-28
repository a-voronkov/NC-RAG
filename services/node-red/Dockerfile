FROM nodered/node-red:4.1

# Install AMQP module for RabbitMQ integration
USER root
RUN npm install node-red-contrib-amqp

COPY flows.json /usr/src/node-red/flows_template.json
COPY init-entrypoint.sh /usr/src/node-red/init-entrypoint.sh
RUN chown node-red:node-red /usr/src/node-red/init-entrypoint.sh     && chmod +x /usr/src/node-red/init-entrypoint.sh

USER node-red
ENTRYPOINT ["/usr/src/node-red/init-entrypoint.sh"]
