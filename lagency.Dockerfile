FROM debian AS downloader

ENV VERSION=6.0.2
WORKDIR /downloader
RUN apt-get update && apt-get install -y wget unzip && rm -rf /var/lib/apt/lists/* && \
    wget https://github.com/bs-community/blessing-skin-server/releases/download/${VERSION}/blessing-skin-server-${VERSION}.zip && \
    mkdir src && unzip -d src blessing-skin-server-${VERSION}.zip && \
    rm blessing-skin-server-${VERSION}.zip
FROM php:8.4-apache

ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN install-php-extensions gd mbstring xml zip pgsql mysqli && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/blessing-skin
ENV APACHE_DOCUMENT_ROOT=/var/www/blessing-skin/public
COPY --from=downloader /downloader/src ./

RUN chown -R www-data:www-data . && \
    sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf && \
    sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf && \
    a2enmod rewrite headers

EXPOSE 80
VOLUME ["/var/www/blessing-skin/storage"]