FROM nodered/node-red:4.1

# Копируем flows.json как шаблон (будет перезаписан если том уже содержит файл)
COPY flows.json /usr/src/node-red/flows_template.json

# Создаем скрипт инициализации
RUN echo '#!/bin/bash\n\
if [ ! -f /data/flows.json ]; then\n\
    echo "Копируем начальный flows.json..."\n\
    cp /usr/src/node-red/flows_template.json /data/flows.json\n\
    chown node-red:node-red /data/flows.json\n\
fi\n\
exec /usr/src/node-red/docker-entrypoint.sh "$@"' > /usr/src/node-red/init-entrypoint.sh \
    && chmod +x /usr/src/node-red/init-entrypoint.sh

ENTRYPOINT ["/usr/src/node-red/init-entrypoint.sh"]