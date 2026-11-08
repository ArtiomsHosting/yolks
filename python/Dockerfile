ARG PYTHON_VERSION
ARG UV_VERSION=0.13.7

FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv

FROM python:${PYTHON_VERSION}-slim-trixie

ARG PYTHON_VERSION

LABEL org.opencontainers.image.title="Python ${PYTHON_VERSION}"
LABEL org.opencontainers.image.description="Python ${PYTHON_VERSION} runtime for Pterodactyl and Pelican servers"
LABEL org.opencontainers.image.source="https://github.com/ArtiomsHosting/yolks"
LABEL org.opencontainers.image.licenses="MIT"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        g++ \
        gcc \
        git \
        iproute2 \
        make \
        tini \
        tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --home-dir /home/container --shell /bin/bash container

COPY --from=uv /uv /usr/local/bin/uv
COPY --chmod=0755 entrypoint.sh /entrypoint.sh
COPY --chmod=0755 start-app /usr/local/bin/start-app

USER container
ENV USER=container \
    HOME=/home/container \
    VIRTUAL_ENV=/home/container/.venv \
    PATH=/home/container/.venv/bin:${PATH} \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    UV_PROJECT_ENVIRONMENT=/home/container/.venv \
    UV_PYTHON_DOWNLOADS=never \
    UV_NO_CACHE=1 \
    UV_LINK_MODE=copy \
    UV_NO_PROGRESS=1
WORKDIR /home/container

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]
