#!/bin/sh
set -e

if [ ! -f /data/flows.json ]; then
    cp /usr/src/node-red/flows_template.json /data/flows.json
    chown node-red:node-red /data/flows.json || true
fi

exec /usr/src/node-red/entrypoint.sh "$@"

