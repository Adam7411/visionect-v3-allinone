#!/command/with-contenv bash
set -e

DB_PASS="{{ .options.db_password }}"
SERVER_ADDR="{{ .options.server_address }}"
CUSTOM_PORT="{{ .options.custom_http_port }}"
VISIONECT_DEBUG="{{ .options.visionect_debug }}"

export DB2_1_PORT_5432_TCP_ADDR=localhost
export DB2_1_PORT_5432_TCP_USER=visionect
export DB2_1_PORT_5432_TCP_PASS="${DB_PASS}"
export DB2_1_PORT_5432_TCP_DB=koala
export REDIS_ADDRESS=localhost:6379
export VISIONECT_SERVER_ADDRESS="${SERVER_ADDR}"
export VISIONECT_HTTP_PORT="${CUSTOM_PORT}"

if [ "${VISIONECT_DEBUG}" = "true" ]; then
  export VISIONECT_DEBUG=1
else
  unset VISIONECT_DEBUG
fi

echo "[cont-init] Zmiennie środowiskowe ustawione."
