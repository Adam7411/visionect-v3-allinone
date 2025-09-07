#!/bin/sh
set -e

OPTS="/data/options.json"

# 1) TIMEZONE z opcji lub z $TZ (od Supervisora)
TZ_OPT="$(jq -r '.timezone // empty' "$OPTS" 2>/dev/null || true)"
if [ -n "$TZ_OPT" ] && [ "$TZ_OPT" != "auto" ]; then
  export TIMEZONE="$TZ_OPT"
elif [ -n "$TZ" ]; then
  export TIMEZONE="$TZ"
fi
if [ -n "$TIMEZONE" ]; then
  echo "Setting TIMEZONE=$TIMEZONE"
else
  echo "No TIMEZONE set; using base image default."
fi

# 2) Bind address – domyślnie 0.0.0.0 aby wystawić usługi na host
BIND_ADDR="$(jq -r '.bind_address // "0.0.0.0"' "$OPTS" 2>/dev/null || echo "0.0.0.0")"
echo "Binding Visionect services to ${BIND_ADDR}"

for f in /etc/supervisor/conf.d/*.conf; do
  [ -f "$f" ] || continue
  sed -i -E "s/(127\.0\.0\.1|localhost)/${BIND_ADDR}/g" "$f" || true
done

# 3) Start właściwych usług (supervisord używany przez obraz Visionect)
exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
