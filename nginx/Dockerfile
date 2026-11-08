FROM nginx:stable-trixie

LABEL org.opencontainers.image.title="Nginx"
LABEL org.opencontainers.image.description="Nginx web server for static sites on Pterodactyl and Pelican servers"
LABEL org.opencontainers.image.source="https://github.com/ArtiomsHosting/yolks"
LABEL org.opencontainers.image.licenses="MIT"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        iproute2 \
        tini \
        tzdata \
    && rm -rf /var/lib/apt/lists/* /etc/nginx/conf.d \
    && ln -s /tmp/nginx/server-port.conf /etc/nginx/server-port.conf \
    && useradd --create-home --home-dir /home/container --shell /bin/bash container

COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/no-php.conf /etc/nginx/php.conf
COPY defaults/default.conf /usr/local/share/start-nginx/default.conf
COPY --chmod=0755 entrypoint.sh /entrypoint.sh
COPY --chmod=0755 start-nginx /usr/local/bin/start-nginx

USER container
ENV USER=container \
    HOME=/home/container
WORKDIR /home/container

STOPSIGNAL SIGINT
ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]
