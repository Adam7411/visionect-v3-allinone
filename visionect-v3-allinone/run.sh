#!/bin/bash
set -euo pipefail

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
HEALTH_GRACE_SECONDS=$(jq -r '.healthcheck_grace // "90"' "$OPTIONS_JSON" 2>/dev/null || echo "90")

VISIONECT_SERVER_ADDRESS="$VSA_RAW"
if [ "$VISIONECT_SERVER_ADDRESS" = "localhost" ]; then
  HOST_IP_CAND=$(ip route 2>/dev/null | awk '/default/ {print $3}' | head -n1 || true)
  if [[ "$HOST_IP_CAND" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    VISIONECT_SERVER_ADDRESS="$HOST_IP_CAND"
    log "Auto-detected host IP: $VISIONECT_SERVER_ADDRESS"
  else
    log "Keeping localhost as Visionect address (no reliable IP). Set visionect_server_address in add-on config to LAN IP."
  fi
fi

log "Visionect address (final): ${VISIONECT_SERVER_ADDRESS}"
log "Bind address: ${BIND_ADDR}"

# --- Katalogi danych / logów
mkdir -p /data/redis /data/pgdata /data/logs
chown -R postgres:postgres /data/pgdata

# Delikatna migracja logów:
# 1. Jeśli /var/log/vss jest już symlink -> OK
# 2. Jeśli jest katalogiem: jeśli pusty -> zamieniamy na symlink; jeśli niepusty -> kopiujemy do /data/logs i potem (jeśli brak otwartych plików) próbujemy zamienić
if [ -L /var/log/vss ]; then
  log "Log dir already symlinked."
elif [ -d /var/log/vss ]; then
  if [ -z "$(ls -A /var/log/vss 2>/dev/null)" ]; then
    log "Replacing empty /var/log/vss with symlink to /data/logs"
    rmdir /var/log/vss 2>/dev/null || true
    ln -s /data/logs /var/log/vss 2>/dev/null || log "WARN: could not create symlink (will fallback to original path)."
  else
    log "Existing /var/log/vss not empty; copying its content to /data/logs (one-time)."
    cp -an /var/log/vss/* /data/logs/ 2>/dev/null || true
    # Spróbujmy tylko jeśli brak otwartych plików (brak procesów jeszcze)
    if ! lsof +D /var/log/vss >/dev/null 2>&1; then
      log "Attempting safe replace of /var/log/vss with symlink."
      mv /var/log/vss /var/log/vss.orig.$(date +%s)
      ln -s /data/logs /var/log/vss || log "WARN: symlink replace failed – leaving original directory."
    else
      log "Active file handles detected in /var/log/vss; skipping symlink replacement."
    fi
  fi
else
  log "Creating symlink /var/log/vss -> /data/logs (path absent)"
  ln -s /data/logs /var/log/vss 2>/dev/null || true
fi

# --- Start Redis
log "Starting redis-server ..."
redis-server --port 6379 --dir /data/redis --save "" --appendonly no &
REDIS_PID=$!

# --- Lokalizacja Postgresa
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
  log "ERROR: Missing Postgres binaries"; kill $REDIS_PID || true; exit 1
fi

log "Using postgres: $POSTGRES_BIN"

# --- Inicjalizacja
if [ ! -s /data/pgdata/PG_VERSION ]; then
  log "Initializing PostgreSQL cluster..."
  su - postgres -c "$INITDB_BIN -D /data/pgdata -E UTF8"
  echo "listen_addresses = '127.0.0.1'" >> /data/pgdata/postgresql.conf
  echo "host all all 127.0.0.1/32 trust" >> /data/pgdata/pg_hba.conf
else
  log "PostgreSQL cluster already initialized."
fi

log "Starting PostgreSQL ..."
su - postgres -c "$POSTGRES_BIN -D /data/pgdata" &
POSTGRES_PID=$!

# --- Czekanie
log "Waiting for PostgreSQL readiness..."
for i in {1..60}; do
  if "$PSQL_BIN" -h 127.0.0.1 -U postgres -c "SELECT 1" >/dev/null 2>&1; then READY=1; break; fi
  sleep 1
done
if [ "${READY:-0}" != "1" ]; then
  log "ERROR: PostgreSQL not ready"; kill $REDIS_PID $POSTGRES_PID || true; exit 1
fi
log "PostgreSQL is ready."

# --- Użytkownik / baza
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

# --- Zmienne
export DB2_1_PORT_5432_TCP_ADDR="127.0.0.1"
export DB2_1_PORT_5432_TCP_USER="${PG_APP_USER}"
export DB2_1_PORT_5432_TCP_PASS="${PG_APP_PASS}"
export DB2_1_PORT_5432_TCP_DB="${PG_APP_DB}"
export REDIS_ADDRESS="127.0.0.1:6379"
export VISIONECT_SERVER_ADDRESS="${VISIONECT_SERVER_ADDRESS}"

# --- Patch supervisor (opcjonalny)
if [ -d /etc/supervisor/conf.d ]; then
  for f in /etc/supervisor/conf.d/*.conf; do
    [ -f "$f" ] || continue
    sed -i -E 's/\bpostgres\b/127.0.0.1/g; s/\bredis\b/127.0.0.1/g' "$f" || true
  done
fi

# --- Healthcheck (z opóźnieniem)
health_loop() {
  sleep "$HEALTH_GRACE_SECONDS"
  log "[health] Starting after grace=${HEALTH_GRACE_SECONDS}s url=${HEALTH_URL}"
  FAILS=0
  while sleep "$HEALTH_INTERVAL"; do
    if curl -fsS -m 6 "$HEALTH_URL" >/dev/null 2>&1; then
      FAILS=0
    else
      FAILS=$((FAILS+1))
      log "[health] Fail $FAILS/$HEALTH_FAILS"
      if [ "$FAILS" -ge "$HEALTH_FAILS" ]; then
        log "[health] Exiting (too many failures)"
        kill $REDIS_PID $POSTGRES_PID 2>/dev/null || true
        exit 1
      fi
    fi
  done
}

if [ "$HEALTH_ENABLED" = "true" ]; then
  health_loop &
fi

# --- Start Visionect
if command -v /usr/bin/supervisord >/dev/null 2>&1; then
  log "Starting supervisord (Visionect stack)..."
  exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
else
  log "ERROR: supervisord not found."
  sleep 600
  exit 1
fi
