ARG BUILD_FROM
FROM ${BUILD_FROM}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql postgresql-contrib \
    redis-server \
    jq \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Utwórz użytkownika postgres jeśli obraz go nie ma (ostrożnie – jeśli istnieje, ignore)
RUN id postgres 2>/dev/null || useradd -r -s /bin/bash postgres

# Katalogi na dane
RUN mkdir -p /data/pgdata /data/redis && chown -R postgres:postgres /data/pgdata

# Skopiuj nasze skrypty
COPY rootfs/usr/local/bin/init_pg.sh /usr/local/bin/init_pg.sh
COPY run.sh /run.sh

RUN chmod 755 /usr/local/bin/init_pg.sh /run.sh

EXPOSE 8081 11113

# Domyślne uruchomienie
ENTRYPOINT ["/run.sh"]
