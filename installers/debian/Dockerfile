FROM debian:trixie-slim

LABEL org.opencontainers.image.title="Debian installer"
LABEL org.opencontainers.image.description="Runs egg install scripts for Pterodactyl and Pelican servers"
LABEL org.opencontainers.image.source="https://github.com/ArtiomsHosting/yolks"
LABEL org.opencontainers.image.licenses="MIT"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        jq \
        tar \
        unzip \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /mnt/server
