#!/bin/sh
# flowz exec: step — deploy domdev on FreeBSD via dail.
# public/ is prebuilt and committed, so no build step.
set -eu

DAIL="${DAIL:-doas dail}"
IP="${IP:-10.100.0.12}"
PORT="${PORT:-8300}"

$DAIL run domdev.dail -p "${PORT}:8080" --ip "$IP" --rebuild

echo "domdev deployed. http://<host>:${PORT}"
