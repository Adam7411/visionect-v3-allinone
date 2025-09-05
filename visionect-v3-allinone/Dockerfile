ARG BUILD_FROM
FROM ${BUILD_FROM}

# Instaluj dodatkowe pakiety potrzebne dla Home Assistant Add-on
RUN apt-get update && apt-get install -y \
    postgresql-client \
    redis-tools \
    s6-overlay \
    && rm -rf /var/lib/apt/lists/*

# Skopiuj skrypty startowe i konfigurację
COPY rootfs /

# Ustaw uprawnienia
RUN chmod a+x /etc/services.d/*/run /etc/cont-init.d/*

# Zdefiniuj porty
EXPOSE 8081 11113

# Użyj s6-overlay jako init system
ENTRYPOINT ["/init"]
