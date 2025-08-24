FROM nodered/node-red:4.1

COPY flows.json /usr/src/node-red/flows_template.json

RUN echo '#!/bin/bash\n\
if [ ! -f /data/flows.json ]; then\n\
    cp /usr/src/node-red/flows_template.json /data/flows.json\n\
    chown node-red:node-red /data/flows.json\n\
fi\n\
exec /usr/src/node-red/docker-entrypoint.sh "$@"' > /usr/src/node-red/init-entrypoint.sh \
    && chmod +x /usr/src/node-red/init-entrypoint.sh

ENTRYPOINT ["/usr/src/node-red/init-entrypoint.sh"]