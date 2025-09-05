#!/usr/bin/with-contenv bash
set -euo pipefail

PGHOST="127.0.0.1"
PGPORT="5432"
PGUSER="postgres"

APP_USER=$(jq -r '.postgres_user' /data/options.json)
APP_PASS=$(jq -r '.postgres_password' /data/options.json)
APP_DB=$(jq -r '.postgres_db' /data/options.json)

echo "[init_pg] Waiting for PostgreSQL..."
for i in {1..60}; do
  if pg_isready -h "${PGHOST}" -p "${PGPORT}" -q; then
    break
  fi
  sleep 1
done

if ! pg_isready -h "${PGHOST}" -p "${PGPORT}" -q; then
  echo "[init_pg] ERROR: PostgreSQL not ready after 60s" >&2
  exit 1
fi

EXISTS_USER=$(psql -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -Atc "SELECT 1 FROM pg_roles WHERE rolname='${APP_USER}';" || true)
if [ "${EXISTS_USER}" != "1" ]; then
  echo "[init_pg] Creating user '${APP_USER}'"
  psql -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -c "CREATE USER ${APP_USER} WITH LOGIN PASSWORD '${APP_PASS}';"
else
  echo "[init_pg] Updating password for user '${APP_USER}'"
  psql -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -c "ALTER USER ${APP_USER} WITH PASSWORD '${APP_PASS}';"
fi

EXISTS_DB=$(psql -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -Atc "SELECT 1 FROM pg_database WHERE datname='${APP_DB}';" || true)
if [ "${EXISTS_DB}" != "1" ]; then
  echo "[init_pg] Creating database '${APP_DB}' owned by '${APP_USER}'"
  psql -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -c "CREATE DATABASE ${APP_DB} OWNER ${APP_USER};"
fi

echo "[init_pg] PostgreSQL ready."