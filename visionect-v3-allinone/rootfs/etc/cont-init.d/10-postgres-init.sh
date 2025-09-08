#!/command/with-contenv bash
set -e

if [ ! -s "${PGDATA}/PG_VERSION" ]; then
  echo "[postgres-init] Inicjalizacja..."
  pg_ctl initdb -D "${PGDATA}"
  echo "listen_addresses='*'" >> "${PGDATA}/postgresql.conf"
  # Start tymczasowy
  pg_ctl start -D "${PGDATA}" -o "-c listen_addresses=localhost" >/dev/null 2>&1
  sleep 3
  psql --username=postgres --command "CREATE USER visionect WITH PASSWORD '${DB2_1_PORT_5432_TCP_PASS}';"
  psql --username=postgres --command "CREATE DATABASE koala OWNER visionect;"
  pg_ctl stop -D "${PGDATA}" -m fast
  echo "[postgres-init] Gotowe."
else
  echo "[postgres-init] Istniejące dane – pomijam."
fi
