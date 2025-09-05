# Budujemy dodatek bezpośrednio na obrazie Visionect per arch przez BUILD_FROM (HA ustawia to z build.yaml).
ARG BUILD_FROM
FROM ${BUILD_FROM}

# HA przekazuje BUILD_ARCH (amd64, aarch64, armv7)
ARG BUILD_ARCH
ARG S6_OVERLAY_VERSION

# Używamy /bin/sh, żeby działało zarówno na Debian/Ubuntu jak i Alpine
SHELL ["/bin/sh", "-c"]

# Upewnij się, że mamy uprawnienia roota do instalacji pakietów
USER root

# Podstawowe narzędzia + PostgreSQL + Redis + bash (wymagany przez skrypty) + jq + xz + curl
# Obsłuż Debian/Ubuntu (apt-get) i Alpine (apk)
RUN if command -v apt-get >/dev/null 2>&1; then \
      apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates curl xz-utils jq bash \
        postgresql redis-server redis-tools && \
      rm -rf /var/lib/apt/lists/*; \
    elif command -v apk >/dev/null 2>&1; then \
      apk add --no-cache ca-certificates curl xz jq bash \
        postgresql redis redis-cli; \
    else \
      echo "Unsupported base image: no apt-get or apk available." >&2; \
      exit 1; \
    fi

# Wyznacz architekturę s6-overlay na podstawie BUILD_ARCH
# amd64 -> x86_64, aarch64 -> aarch64, armv7 -> armhf
RUN case "${BUILD_ARCH}" in \
      amd64)  export S6_ARCH="x86_64" ;; \
      aarch64) export S6_ARCH="aarch64" ;; \
      armv7) export S6_ARCH="armhf" ;; \
      *) echo "Unsupported BUILD_ARCH: ${BUILD_ARCH}" >&2; exit 1 ;; \
    esac && \
    mkdir -p /tmp/s6 && \
    curl -fsSL -o /tmp/s6/s6-overlay-noarch.tar.xz https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz && \
    curl -fsSL -o /tmp/s6/s6-overlay-${S6_ARCH}.tar.xz https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz && \
    xz -d /tmp/s6/s6-overlay-noarch.tar.xz && \
    xz -d /tmp/s6/s6-overlay-${S6_ARCH}.tar.xz && \
    tar -C / -xpf /tmp/s6/s6-overlay-noarch.tar && \
    tar -C / -xpf /tmp/s6/s6-overlay-${S6_ARCH}.tar && \
    rm -rf /tmp/s6

# Katalogi danych
RUN mkdir -p /data/pgdata /data/redis && chown -R root:root /data

# Usługi s6 oraz skrypty init
COPY rootfs/ /

# Ustaw locale
ENV LANG=C.UTF-8

# HA uruchomi /init (s6-overlay) dzięki init: true
