#!/bin/bash
set -euo pipefail

OPTIONS_JSON="/data/options.json"

# --- Funkcja logowania
log() { echo "[$(date +'%H:%M:%S')] $*"; }

# --- Odczyt opcji
PG_APP_USER=$(jq -r '.postgres_user // "visionect"' "$OPTIONS_JSON" 2>/dev/null || echo "visionect")
PG_APP_PASS=$(jq -r '.postgres_password // "visionect"' "$OPTIONS_JSON" 2>/dev/null || echo "visionect")
PG_APP_DB=$(jq -r '.postgres_db // "koala"' "$OPTIONS_JSON" 2>/dev/null || echo "koala")
VSA=$(jq -r '.visionect_server_address // "localhost"' "$OPTIONS_JSON" 2>/dev/null || echo "localhost")
BIND_ADDR=$(jq -r '.bind_address // "0.0.0.0"' "$OPTIONS_JSON" 2>/dev/null || echo "0.0.0.0")

log "Visionect address: ${VSA}"
log "Bind address: ${BIND_ADDR}"

# --- Katalogi danych
mkdir -p /data/redis
mkdir -p /data/pgdata
chown -R postgres:postgres /data/pgdata

# --- Redis
log "Starting redis-server..."
redis-server --port 6379 --dir /data/redis --save "" --appendonly no &
REDIS_PID=$!

# --- Znajdź initdb i postgres
detect_bin() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    command -v "$name"
    return 0
  fi
  local alt
  alt=$(ls /usr/lib/postgresql/*/bin/"$name" 2>/dev/null | head -n1 || true)
  if [ -n "$alt" ]; then
    echo "$alt"
    return 0
  fi
  return 1
}

INITDB_BIN=$(detect_bin initdb || true)
POSTGRES_BIN=$(detect_bin postgres || true)
PSQL_BIN=$(detect_bin psql || true)

if [ -z "$INITDB_BIN" ]; then
  log "ERROR: Nie znaleziono initdb (brak pakietu serwera Postgres?)."
  log "Zainstalowane pliki w /usr/lib/postgresql:"
  ls -1 /usr/lib/postgresql 2>/dev/null || true
  kill $REDIS_PID || true
  exit 1
fi
if [ -z "$POSTGRES_BIN" ]; then
  log "ERROR: Nie znaleziono postgres binarki."
  kill $REDIS_PID || true
  exit 1
fi
if [ -z "$PSQL_BIN" ]; then
  log "ERROR: Nie znaleziono psql (klient)."
  kill $REDIS_PID || true
  exit 1
fi

log "Using initdb: $INITDB_BIN"
log "Using postgres: $POSTGRES_BIN"
log "Using psql: $PSQL_BIN"

# --- Inicjalizacja klastra
if [ ! -s /data/pgdata/PG_VERSION ]; then
  log "Initializing PostgreSQL cluster in /data/pgdata"
  su - postgres -c "$INITDB_BIN -D /data/pgdata -E UTF8"
  echo "listen_addresses = '127.0.0.1'" >> /data/pgdata/postgresql.conf
  echo "host all all 127.0.0.1/32 trust" >> /data/pgdata/pg_hba.conf
else
  log "PostgreSQL cluster already initialized."
fi

# --- Start Postgresa
log "Starting PostgreSQL..."
su - postgres -c "$POSTGRES_BIN -D /data/pgdata" &
POSTGRES_PID=$!

# --- Czekaj na gotowość Postgresa
log "Waiting for PostgreSQL readiness..."
for i in {1..60}; do
  if "$PSQL_BIN" -h 127.0.0.1 -U postgres -c "SELECT 1" >/dev/null 2>&1; then
    READY=1
    break
  fi
  sleep 1
done
if [ "${READY:-0}" != "1" ]; then
  log "ERROR: PostgreSQL not ready after 60s"
  kill $REDIS_PID $POSTGRES_PID || true
  exit 1
fi
log "PostgreSQL is ready."

# --- Użytkownik i baza
log "Ensuring role/database..."
EXISTS_USER=$("$PSQL_BIN" -h 127.0.0.1 -U postgres -Atc "SELECT 1 FROM pg_roles WHERE rolname='${PG_APP_USER}';" || true)
if [ "$EXISTS_USER" != "1" ]; then
  "$PSQL_BIN" -h 127.0.0.1 -U postgres -c "CREATE USER ${PG_APP_USER} WITH LOGIN PASSWORD '${PG_APP_PASS}';"
else
  "$PSQL_BIN" -h 127.0.0.1 -U postgres -c "ALTER USER ${PG_APP_USER} WITH PASSWORD '${PG_APP_PASS}';"
fi
EXISTS_DB=$("$PSQL_BIN" -h 127.0.0.1 -U postgres -Atc "SELECT 1 FROM pg_database WHERE datname='${PG_APP_DB}';" || true)
if [ "$EXISTS_DB" != "1" ]; then
  "$PSQL_BIN" -h 127.0.0.1 -U postgres -c "CREATE DATABASE ${PG_APP_DB} OWNER ${PG_APP_USER};"
fi

# --- Zmienne Visionect
export DB2_1_PORT_5432_TCP_ADDR="127.0.0.1"
export DB2_1_PORT_5432_TCP_USER="${PG_APP_USER}"
export DB2_1_PORT_5432_TCP_PASS="${PG_APP_PASS}"
export DB2_1_PORT_5432_TCP_DB="${PG_APP_DB}"
export REDIS_ADDRESS="127.0.0.1:6379"
export VISIONECT_SERVER_ADDRESS="${VSA}"

# --- Szukanie Visionect binarki
log "Launching Visionect..."
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
    log "Using Visionect entrypoint: $P"
    exec "$P"
  fi
done

log "ERROR: Visionect entrypoint not found."
log "Root listing:"
ls -l /
log "/usr/local/bin listing:"
ls -l /usr/local/bin || true
log "Sleeping 60s for debug..."
sleep 60
exit 1
