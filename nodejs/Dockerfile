ARG NODE_VERSION

FROM node:${NODE_VERSION}-trixie-slim

ARG NODE_VERSION
ARG PNPM_VERSION=12.16.1
ARG YARN_VERSION=1.22.22
ARG COREPACK_VERSION=0.36.0

LABEL org.opencontainers.image.title="Node.js ${NODE_VERSION}"
LABEL org.opencontainers.image.description="Node.js ${NODE_VERSION} runtime for Pterodactyl and Pelican servers"
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
    && npm install --global "pnpm@${PNPM_VERSION}" \
    && if ! command -v yarn >/dev/null; then npm install --global "yarn@${YARN_VERSION}"; fi \
    && if ! command -v corepack >/dev/null; then \
        npm install --prefix /opt/corepack "corepack@${COREPACK_VERSION}" \
        && ln -s /opt/corepack/node_modules/.bin/corepack /usr/local/bin/corepack; \
    fi \
    && npm cache clean --force \
    && useradd --create-home --home-dir /home/container --shell /bin/bash container

COPY --chmod=0755 entrypoint.sh /entrypoint.sh
COPY --chmod=0755 start-app /usr/local/bin/start-app

USER container
ENV USER=container \
    HOME=/home/container \
    NPM_CONFIG_UPDATE_NOTIFIER=false \
    NPM_CONFIG_FUND=false \
    pnpm_config_dangerously_allow_all_builds=true \
    COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
    COREPACK_ENABLE_AUTO_PIN=0
WORKDIR /home/container

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]
