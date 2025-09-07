#!/bin/bash
set -euo pipefail

OPTIONS_JSON="/data/options.json"

# Odczyt opcji (z fallbackami)
PG_APP_USER=$(jq -r '.postgres_user // "visionect"' "$OPTIONS_JSON" 2>/dev/null || echo "visionect")
PG_APP_PASS=$(jq -r '.postgres_password // "visionect"' "$OPTIONS_JSON" 2>/dev/null || echo "visionect")
PG_APP_DB=$(jq -r '.postgres_db // "koala"' "$OPTIONS_JSON" 2>/dev/null || echo "koala")
VSA=$(jq -r '.visionect_server_address // "localhost"' "$OPTIONS_JSON" 2>/dev/null || echo "localhost")
BIND_ADDR=$(jq -r '.bind_address // "0.0.0.0"' "$OPTIONS_JSON" 2>/dev/null || echo "0.0.0.0")

echo "[init] Visionect address: ${VSA}"
echo "[init] Bind address: ${BIND_ADDR}"

# 1. Start Redis (foreground w tle)
echo "[redis] Starting redis-server..."
redis-server --port 6379 --dir /data/redis --save "" --appendonly no &
REDIS_PID=$!

# 2. Inicjalizacja + start PostgreSQL
if [ ! -s /data/pgdata/PG_VERSION ]; then
  echo "[postgres] Initializing cluster in /data/pgdata"
  su - postgres -c "initdb -D /data/pgdata -E UTF8"
  echo "listen_addresses = '127.0.0.1'" >> /data/pgdata/postgresql.conf
  echo "host all all 127.0.0.1/32 trust" >> /data/pgdata/pg_hba.conf
fi
echo "[postgres] Starting postgres..."
su - postgres -c "postgres -D /data/pgdata" &
POSTGRES_PID=$!

# 3. Czekaj na Postgresa
echo "[postgres] Waiting for server..."
for i in {1..60}; do
  if pg_isready -h 127.0.0.1 -p 5432 >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
if ! pg_isready -h 127.0.0.1 -p 5432 >/dev/null 2>&1; then
  echo "[postgres] ERROR: Not ready after 60s"
  exit 1
fi

# 4. Tworzenie użytkownika/bazy
echo "[postgres] Ensuring role/database..."
EXISTS_USER=$(psql -h 127.0.0.1 -U postgres -Atc "SELECT 1 FROM pg_roles WHERE rolname='${PG_APP_USER}';" || true)
if [ "${EXISTS_USER}" != "1" ]; then
  psql -h 127.0.0.1 -U postgres -c "CREATE USER ${PG_APP_USER} WITH LOGIN PASSWORD '${PG_APP_PASS}';"
else
  psql -h 127.0.0.1 -U postgres -c "ALTER USER ${PG_APP_USER} WITH PASSWORD '${PG_APP_PASS}';"
fi
EXISTS_DB=$(psql -h 127.0.0.1 -U postgres -Atc "SELECT 1 FROM pg_database WHERE datname='${PG_APP_DB}';" || true)
if [ "${EXISTS_DB}" != "1" ]; then
  psql -h 127.0.0.1 -U postgres -c "CREATE DATABASE ${PG_APP_DB} OWNER ${PG_APP_USER};"
fi

# 5. Ustaw zmienne Visionect
export DB2_1_PORT_5432_TCP_ADDR="127.0.0.1"
export DB2_1_PORT_5432_TCP_USER="${PG_APP_USER}"
export DB2_1_PORT_5432_TCP_PASS="${PG_APP_PASS}"
export DB2_1_PORT_5432_TCP_DB="${PG_APP_DB}"
export REDIS_ADDRESS="127.0.0.1:6379"
export VISIONECT_SERVER_ADDRESS="${VSA}"

# 6. Uruchom Visionect (szukamy binarki/skryptu)
echo "[vss] Launching Visionect..."
CANDIDATES=(
  "/docker-entrypoint.sh"
  "/entrypoint.sh"
  "/start.sh"
  "/usr/local/bin/start.sh"
  "/usr/bin/vss"
  "/usr/local/bin/vss"
  "/visionect-server"
  "/app"
)

for P in "${CANDIDATES[@]}"; do
  if [ -x "$P" ]; then
    echo "[vss] Using $P"
    exec "$P"
  fi
done

echo "[vss] ERROR: No Visionect entrypoint found."
echo "Listing /:"
ls -l /
echo "Listing /usr/local/bin:"
ls -l /usr/local/bin || true
# Gdyby chcesz debugować bez wyjścia:
sleep 10
exit 1
