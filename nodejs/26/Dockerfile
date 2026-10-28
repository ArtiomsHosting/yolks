FROM node:26-trixie-slim

ARG PNPM_VERSION=12.16.1
ARG YARN_VERSION=1.22.22

LABEL org.opencontainers.image.title="Node.js 26"
LABEL org.opencontainers.image.description="Node.js 26 runtime for Pterodactyl and Pelican servers"
LABEL org.opencontainers.image.source="https://github.com/ArtiomsHosting/yolks"
LABEL org.opencontainers.image.licenses="MIT"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        g++ \
        git \
        iproute2 \
        make \
        python3 \
        tini \
        tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && npm install --global "pnpm@${PNPM_VERSION}" "yarn@${YARN_VERSION}" \
    && npm cache clean --force \
    && useradd --create-home --home-dir /home/container --shell /bin/bash container

COPY --chmod=0755 entrypoint.sh /entrypoint.sh
COPY --chmod=0755 start-app /usr/local/bin/start-app

USER container
ENV USER=container \
    HOME=/home/container \
    NPM_CONFIG_UPDATE_NOTIFIER=false \
    NPM_CONFIG_FUND=false
WORKDIR /home/container

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]
