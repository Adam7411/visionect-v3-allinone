#!/usr/bin/with-contenv bash
set -euo pipefail

OPTS="/data/options.json"
BIND_ADDR="$(jq -r '.bind_address // "0.0.0.0"' "$OPTS" 2>/dev/null || echo "0.0.0.0")"
echo "Binding Visionect services to ${BIND_ADDR}"

# Podmień 127.0.0.1/localhost na wskazany adres we wszystkich usługach Visionect
for f in /etc/supervisor/conf.d/*.conf; do
  [ -f "$f" ] || continue
  sed -i -E "s/(127\.0\.0\.1|localhost)/${BIND_ADDR}/g" "$f" || true
done
