#!/usr/bin/with-contenv bash
set -euo pipefail
mkdir -p /data/pgdata /data/redis
chown -R postgres:postgres /data/pgdata || true