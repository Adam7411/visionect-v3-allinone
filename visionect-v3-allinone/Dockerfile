ARG BUILD_FROM
FROM ${BUILD_FROM}

# Instaluj tylko niezbędne pakiety
RUN apt-get update && apt-get install -y \
    postgresql-client \
    redis-tools \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Skopiuj strukturę rootfs (która już istnieje w Twoim repo)
COPY rootfs /

# Ustaw uprawnienia dla skryptów
RUN chmod a+x /usr/local/bin/init_pg.sh \
    && chmod a+x /etc/services.d/*/run \
    && chmod a+x /etc/cont-init.d/*.sh

# Stwórz użytkownika postgres jeśli nie istnieje
RUN useradd -r -s /bin/false postgres || true

# Porty
EXPOSE 8081 11113

# Home Assistant używa własnego init systemu
CMD ["/usr/local/bin/init_pg.sh"]
