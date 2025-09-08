ARG BUILD_FROM
FROM ${BUILD_FROM}

# (Opcjonalnie) ARG VISIONECT_VERSION (jeśli używasz)
ARG VISIONECT_VERSION

# Instalacja zależności (zakładam Debian/Ubuntu base w obrazie Visionect)
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      postgresql redis-server curl ca-certificates tzdata bash coreutils procps \
    && rm -rf /var/lib/apt/lists/*

# Ustawienia katalogów danych
ENV PGDATA=/data/postgres \
    REDIS_DATA=/data/redis \
    VISIONECT_DATA=/data/visionect \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8

# Tworzenie katalogów
RUN mkdir -p /data/postgres /data/redis /data/visionect && \
    chown -R root:root /data

# Kopiowanie rootfs (s6 services + inicjalizacja)
COPY rootfs/ /

# Uprawnienia do skryptów
RUN chmod -R 755 /etc/services.d /etc/cont-init.d

EXPOSE 8081 11113
