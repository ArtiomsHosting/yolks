ARG PHP_VERSION
ARG COMPOSER_VERSION=2.11.1
ARG EXTENSION_INSTALLER_VERSION=2.13.2

FROM composer:${COMPOSER_VERSION} AS composer

FROM mlocati/php-extension-installer:${EXTENSION_INSTALLER_VERSION} AS extension-installer

FROM php:${PHP_VERSION}-fpm-trixie

ARG PHP_VERSION

LABEL org.opencontainers.image.title="Nginx with PHP ${PHP_VERSION}"
LABEL org.opencontainers.image.description="Nginx web server with PHP ${PHP_VERSION} FPM and Composer for Pterodactyl and Pelican servers"
LABEL org.opencontainers.image.source="https://github.com/ArtiomsHosting/yolks"
LABEL org.opencontainers.image.licenses="MIT"

RUN curl -fsSL https://nginx.org/keys/nginx_signing.key -o /usr/share/keyrings/nginx.asc \
    && echo 'deb [signed-by=/usr/share/keyrings/nginx.asc] https://nginx.org/packages/debian trixie nginx' \
        > /etc/apt/sources.list.d/nginx.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        iproute2 \
        nginx \
        tini \
        tzdata \
        unzip \
    && rm -rf /var/lib/apt/lists/* /etc/nginx/conf.d \
    && ln -s /tmp/nginx/server-port.conf /etc/nginx/server-port.conf \
    && useradd --create-home --home-dir /home/container --shell /bin/bash container

RUN --mount=type=bind,from=extension-installer,source=/usr/bin/install-php-extensions,target=/usr/local/bin/install-php-extensions \
    install-php-extensions \
        bcmath \
        exif \
        gd \
        intl \
        mysqli \
        opcache \
        pcntl \
        pdo_mysql \
        pdo_pgsql \
        pgsql \
        redis \
        zip \
    && cp "${PHP_INI_DIR}/php.ini-production" "${PHP_INI_DIR}/php.ini"

COPY --from=composer /usr/bin/composer /usr/local/bin/composer
COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/php.conf /etc/nginx/php.conf
COPY config/php-defaults.ini /usr/local/etc/php/conf.d/zz-defaults.ini
COPY defaults/default.conf defaults/php.ini /usr/local/share/start-nginx/
COPY --chmod=0755 entrypoint.sh /entrypoint.sh
COPY --chmod=0755 start-nginx /usr/local/bin/start-nginx

USER container
ENV USER=container \
    HOME=/home/container \
    PHP_INI_SCAN_DIR=:/home/container/php
WORKDIR /home/container

STOPSIGNAL SIGINT
ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]
