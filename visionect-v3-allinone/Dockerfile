# Bazujemy na oficjalnym obrazie Visionect per arch
ARG BUILD_FROM
FROM ${BUILD_FROM}

USER root
SHELL ["/bin/sh", "-c"]

# Narzędzia potrzebne do entrypointa
RUN if command -v apt-get >/dev/null 2>&1; then \
      apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates curl jq bash sed && \
      rm -rf /var/lib/apt/lists/*; \
    elif command -v apk >/dev/null 2>&1; then \
      apk add --no-cache ca-certificates curl jq bash sed; \
    else \
      echo "Unsupported base image: no apt-get or apk available." >&2; \
      exit 1; \
    fi

# Wrapper entrypoint – ustawia TIMEZONE i bind_address, potem startuje supervisord
COPY rootfs/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8081 11113

ENTRYPOINT ["/entrypoint.sh"]
