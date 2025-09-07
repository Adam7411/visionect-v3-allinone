ARG BUILD_FROM
FROM ${BUILD_FROM}

ENV DEBIAN_FRONTEND=noninteractive

# Jeśli wcześniej usunąłeś instalację serwera, upewnij się że te pakiety są
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql postgresql-contrib \
    redis-server \
    jq \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Użytkownik postgres (jeżeli nie istnieje)
RUN id postgres 2>/dev/null || useradd -r -s /bin/bash postgres

# Katalogi danych (mogą też powstać w run.sh, ale to nie szkodzi)
RUN mkdir -p /data/pgdata /data/redis && chown -R postgres:postgres /data/pgdata

COPY run.sh /run.sh
RUN chmod 755 /run.sh

EXPOSE 8081 11113

ENTRYPOINT ["/run.sh"]
