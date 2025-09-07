#!/bin/bash
set -euo pipefail

# Graceful stop
trap 'echo "[STOP] Caught signal, shutting down..."; kill $REDIS_PID $POSTGRES_PID 2>/dev/null || true; exit 0' TERM INT

OPTIONS_JSON="/data/options.json"

log() { echo "[$(date +'%H:%M:%S')] $*"; }

# --- Odczyt opcji
PG_APP_USER=$(jq -r '.postgres_user // "visionect"' "$OPTIONS_JSON" 2>/dev/null || echo "visionect")
PG_APP_PASS=$(jq -r '.postgres_password // "visionect"' "$OPTIONS_JSON" 2>/dev/null || echo "visionect")
PG_APP_DB=$(jq -r '.postgres_db // "koala"' "$OPTIONS_JSON" 2>/dev/null || echo "koala")
VSA_RAW=$(jq -r '.visionect_server_address // "localhost"' "$OPTIONS_JSON" 2>/dev/null || echo "localhost")
BIND_ADDR=$(jq -r '.bind_address // "0.0.0.0"' "$OPTIONS_JSON" 2>/dev/null || echo "0.0.0.0")
HEALTH_ENABLED=$(jq -r '.healthcheck_enable // "true"' "$OPTIONS_JSON" 2>/dev/null || echo "true")
HEALTH_URL=$(jq -r '.healthcheck_url // "http://127.0.0.1:8081"' "$OPTIONS_JSON" 2>/dev/null || echo "http://127.0.0.1:8081")
HEALTH_INTERVAL=$(jq -r '.healthcheck_interval // "30"' "$OPTIONS_JSON" 2>/dev/null || echo "30")
HEALTH_FAILS=$(jq -r '.healthcheck_max_failures // "5"' "$OPTIONS_JSON" 2>/dev/null || echo "5")

# --- Dynamiczne IP jeśli user zostawił localhost
VISIONECT_SERVER_ADDRESS="$VSA_RAW"
if [ "$VISIONECT_SERVER_ADDRESS" = "localhost" ]; then
  HOST_IP_CAND=$(ip route 2>/dev/null | awk '/default/ {print $3}' | head -n1 || true)
  if [[ "$HOST_IP_CAND" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    VISIONECT_SERVER_ADDRESS="$HOST_IP_CAND"
    log "Auto-detected host IP: $VISIONECT_SERVER_ADDRESS (override visionect_server_address w opcjach by wymusić własny)"
  else
    log "Keeping localhost as Visionect address (brak wiarygodnego IP)."
  fi
fi

log "Visionect address (final): ${VISIONECT_SERVER_ADDRESS}"
log "Bind address: ${BIND_ADDR}"

# --- Katalogi danych i logów
mkdir -p /data/redis /data/pgdata /data/logs
chown -R postgres:postgres /data/pgdata
if [ ! -L /var/log/vss ]; then
  if [ -d /var/log/vss ]; then
    cp -a /var/log/vss/* /data/logs/ 2>/dev/null || true
    rm -rf /var/log/vss
  fi
  ln -s /data/logs /var/log/vss
fi

# --- Start Redis
log "Starting redis-server ..."
redis-server --port 6379 --dir /data/redis --save "" --appendonly no &
REDIS_PID=$!

# --- Funkcja lokalizacji binarek Postgresa
detect_bin() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    command -v "$name"; return 0
  fi
  local alt
  alt=$(ls /usr/lib/postgresql/*/bin/"$name" 2>/dev/null | head -n1 || true)
  [ -n "$alt" ] && echo "$alt" && return 0
  return 1
}

INITDB_BIN=$(detect_bin initdb || true)
POSTGRES_BIN=$(detect_bin postgres || true)
PSQL_BIN=$(detect_bin psql || true)

if [ -z "$INITDB_BIN" ] || [ -z "$POSTGRES_BIN" ] || [ -z "$PSQL_BIN" ]; then
  log "ERROR: Missing Postgres binaries (initdb=$INITDB_BIN postgres=$POSTGRES_BIN psql=$PSQL_BIN)"
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
log "Starting PostgreSQL ..."
su - postgres -c "$POSTGRES_BIN -D /data/pgdata" &
POSTGRES_PID=$!

# --- Czekanie na gotowość
log "Waiting for PostgreSQL readiness..."
for i in {1..60}; do
  if "$PSQL_BIN" -h 127.0.0.1 -U postgres -c "SELECT 1" >/dev/null 2>&1; then
    READY=1; break
  fi
  sleep 1
done
if [ "${READY:-0}" != "1" ]; then
  log "ERROR: PostgreSQL not ready after 60s"
  kill $REDIS_PID $POSTGRES_PID || true
  exit 1
fi
log "PostgreSQL is ready."

# --- Użytkownik / baza
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

# --- Zmienne środowiskowe Visionect
export DB2_1_PORT_5432_TCP_ADDR="127.0.0.1"
export DB2_1_PORT_5432_TCP_USER="${PG_APP_USER}"
export DB2_1_PORT_5432_TCP_PASS="${PG_APP_PASS}"
export DB2_1_PORT_5432_TCP_DB="${PG_APP_DB}"
export REDIS_ADDRESS="127.0.0.1:6379"
export VISIONECT_SERVER_ADDRESS="${VISIONECT_SERVER_ADDRESS}"

# --- Patch supervisor (jeśli potrzebne)
if [ -d /etc/supervisor/conf.d ]; then
  log "Patching supervisor conf files (postgres -> 127.0.0.1, redis -> 127.0.0.1)"
  for f in /etc/supervisor/conf.d/*.conf; do
    [ -f "$f" ] || continue
    sed -i -E 's/\bpostgres\b/127.0.0.1/g; s/\bredis\b/127.0.0.1/g' "$f" || true
  done
else
  log "WARNING: /etc/supervisor/conf.d not found."
fi

# --- Healthcheck (lekki)
health_loop() {
  FAILS=0
  log "[health] Loop started (url=$HEALTH_URL interval=${HEALTH_INTERVAL}s max_fails=$HEALTH_FAILS)"
  while sleep "$HEALTH_INTERVAL"; do
    if curl -fsS -m 5 "$HEALTH_URL" >/dev/null 2>&1; then
      FAILS=0
    else
      FAILS=$((FAILS+1))
      log "[health] Fail $FAILS/$HEALTH_FAILS (${HEALTH_URL})"
      if [ "$FAILS" -ge "$HEALTH_FAILS" ]; then
        log "[health] Too many failures - exiting to trigger restart."
        kill $REDIS_PID $POSTGRES_PID 2>/dev/null || true
        exit 1
      fi
    fi
  done
}

if [ "$HEALTH_ENABLED" = "true" ]; then
  health_loop &
  HEALTH_PID=$!
fi

# --- Start Visionect stack
if command -v /usr/bin/supervisord >/dev/null 2>&1; then
  log "Starting supervisord (Visionect stack)..."
  exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
else
  log "ERROR: supervisord not found."
  sleep 600
  exit 1
fi
