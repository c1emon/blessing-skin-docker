FROM clemon7/blessing-skin-server:dev-no-imagemagick

RUN apt update && apt install -y curl wget unzip autoconf pkg-config build-essential libpng-dev && rm -rf /var/lib/apt/lists/*
WORKDIR /build
RUN wget https://imagemagick.org/archive/ImageMagick.tar.gz && mkdir src && tar -xvf ImageMagick.tar.gz --strip-components 1 -C /build/src
WORKDIR /build/src
RUN mkdir /build/dist && ./configure && make -j && make install && ldconfig /usr/local/lib/ && install-php-extensions imagick && rm -rf /builds
COPY php.ini /usr/local/etc/php/
# RUN mkdir /build/dist && ./configure --prefix=/build/dist --disable-installed && make -j && make install