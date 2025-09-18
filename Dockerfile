FROM node:trixie AS frontend_builder

ENV VERSION=6.0.2
WORKDIR /build

RUN apt-get update && apt-get install -y wget unzip curl git && rm -rf /var/lib/apt/lists/* && \
    git clone -b ${VERSION} --depth=1 https://github.com/bs-community/blessing-skin-server.git src

WORKDIR /build/src

RUN yarn install --frozen-lockfile && yarn build && \
    cp resources/assets/src/images/bg.webp public/app/ && \
    cp resources/assets/src/images/favicon.ico public/app/

FROM php:8.4-apache AS builder

ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

WORKDIR /build/src
COPY --from=frontend_builder /build/src /build/src
COPY composer.json .

RUN apt-get update && apt-get install -y wget unzip curl git && rm -rf /var/lib/apt/lists/* && \
    install-php-extensions @composer gd zip && \
    composer update && \
    # composer update 'laravel/framework:^10.0' --with-dependencies && \
    # composer require facade/ignition "^2.17.7" && \
    # composer require --dev 'phpunit/phpunit:^10.0' 'laravel/browser-kit-testing:^7.0' && \
    composer install --prefer-dist --no-dev --no-progress --no-autoloader --no-scripts --no-interaction --ignore-platform-reqs

RUN composer dump-autoload -o --no-dev -n


FROM php:8.4-apache

COPY --from=builder /usr/local/bin/install-php-extensions /usr/local/bin/install-php-extensions

RUN install-php-extensions gd mbstring xml zip pgsql mysqli && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/blessing-skin
ENV APACHE_DOCUMENT_ROOT=/var/www/blessing-skin/public
COPY --from=builder /build/src ./

RUN chown -R www-data:www-data . && \
    sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf && \
    sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf && \
    php artisan key:generate && a2enmod rewrite headers

EXPOSE 80
VOLUME ["/var/www/blessing-skin/storage"]