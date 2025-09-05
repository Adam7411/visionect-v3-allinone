# Budujemy dodatek bezpośrednio na obrazie Visionect, aby zachować jego środowisko.
ARG VSS_IMAGE
FROM ${VSS_IMAGE}

ARG S6_OVERLAY_VERSION
ARG S6_ARCH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Podstawowe narzędzia + PostgreSQL + Redis + jq
# Uwaga: jeśli obraz Visionect jest Alpine, zamień apt-get na apk (patrz README).
RUN if command -v apt-get >/dev/null 2>&1; then \
      apt-get update && \
      apt-get install -y --no-install-recommends \
        ca-certificates curl xz-utils jq \
        postgresql redis-server redis-tools && \
      rm -rf /var/lib/apt/lists/*; \
    else \
      echo "apt-get not found. If base is Alpine, replace with 'apk add --no-cache ...' (see README)." && exit 1; \
    fi

# Instalacja s6-overlay (wymagane przez init: true w HA)
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp/
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz /tmp/
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-${S6_ARCH}.tar.xz && \
    rm -f /tmp/s6-overlay-noarch.tar.xz /tmp/s6-overlay-${S6_ARCH}.tar.xz

# Katalogi danych
RUN mkdir -p /data/pgdata /data/redis && chown -R root:root /data

# Usługi s6 oraz skrypty init
COPY rootfs/ /

# Ustaw locale
ENV LANG=C.UTF-8

# HA uruchomi /init (s6-overlay) dzięki init: true