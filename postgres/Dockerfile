ARG PG_MAJOR

FROM postgres:${PG_MAJOR}-trixie

ARG PG_MAJOR

LABEL org.opencontainers.image.title="PostgreSQL ${PG_MAJOR}"
LABEL org.opencontainers.image.description="PostgreSQL ${PG_MAJOR} with pgvector for Pterodactyl and Pelican servers"
LABEL org.opencontainers.image.source="https://github.com/ArtiomsHosting/yolks"
LABEL org.opencontainers.image.licenses="MIT"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        iproute2 \
        "postgresql-${PG_MAJOR}-pgvector" \
        tini \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --home-dir /home/container --shell /bin/bash container

COPY --chmod=0755 entrypoint.sh /entrypoint.sh
COPY --chmod=0755 start-postgres /usr/local/bin/start-postgres

USER container
ENV USER=container \
    HOME=/home/container \
    PG_MAJOR=${PG_MAJOR} \
    PGDATA=/home/container/postgres_db
WORKDIR /home/container

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]
