#!/bin/bash

# fail fast
set -e

SCRIPT_DIR=`dirname $(readlink -f $0)`
. $SCRIPT_DIR/variables.sh

# mcrypt
echo "**** Downloading libmcrypt ${LIBMCRYPT_VERSION}"
curl -s -L $LIBMCRYPT_URL -o - | tar xj

cd libmcrypt-$LIBMCRYPT_VERSION
./configure \
--prefix=/app/php/local \
--disable-rpath && \
make install

# php
echo "**** Downloading PHP ${PHP_VERSION}"
cd $SCRIPT_DIR
curl -s -L $PHP_URL | tar zx
cd php-${PHP_VERSION}

./configure \
    --prefix=/app/php \
    --with-apxs2=/app/apache/bin/apxs \
    --with-config-file-path=/app/php \
    --with-config-file-scan-dir=/app/php/conf.d/ \
    --disable-debug \
    --disable-rpath \
    --enable-gd-native-ttf \
    --enable-inline-optimization \
    --enable-libxml \
    --enable-mbregex \
    --enable-mbstring \
    --enable-pcntl \
    --enable-soap=shared \
    --enable-zip \
    --with-bz2 \
    --with-curl=/usr/lib \
    --with-gd \
    --with-gettext \
    --with-jpeg-dir \
    --with-mcrypt=/app/php/local \
    --with-iconv \
    --with-mhash \
    --with-mysql \
    --with-mysqli \
    --with-openssl \
    --with-pcre-regex \
    --with-pdo-mysql \
    --with-pgsql \
    --with-pdo-pgsql \
    --with-png-dir \
    --with-imagemagick \
    --with-exif \
    --with-zlib  && \
make && \
make install

# create the php config scan dir
mkdir /app/php/conf.d/

echo "$PHP_VERSION" > VERSION

# composer
echo "**** Downloading Composer"
curl -L -s  $COMPOSER_URL | /app/php/bin/php
mv composer.phar /app/php/bin/composer

# php shared libraries
mkdir /app/php/ext
cp /usr/lib/libmysqlclient.so.16 /app/php/ext/

# apc
echo "**** Downloading APC"
/app/php/bin/pear config-set php_dir /app/php
echo "no" | /app/php/bin/pecl install apc

# libmemcached
echo "**** Downloading libmemcached ${LIBMEMCACHED_VERSION}"
curl --insecure -s -L $LIBMEMCACHED_URL -o - | tar xz

cd libmemcached-${LIBMEMCACHED_VERSION}
./configure --prefix=/app/php/local && \
 make install

# memcached
echo "**** Downloading memcached ${MEMCACHED_VERSION}"
curl -s -L $MEMCACHED_URL -o - | tar xz

cd memcached-${MEMCACHED_VERSION}
sed -i -e '18 s/no, no/yes, yes/' ./config.m4 # Enable memcached json serializer support: YES
sed -i -e '21 s/no, no/yes, yes/' ./config.m4 # Disable memcached sasl support: YES
/app/php/bin/phpize && \
./configure --with-libmemcached-dir=/app/php/local/ --prefix=/app/php --with-php-config=/app/php/bin/php-config && \
make && \
make install

# new relic
echo "**** Downloading New Relic PHP module ${NEWRELIC_VERSION}"
ZEND_MODULE_API_VERSION=`/app/php/bin/phpize --version | grep "Zend Module Api No" | tr -d ' ' | cut -f 2 -d ':'`
PHP_EXTENSION_DIR=`/app/php/bin/php-config --extension-dir`

cd $SCRIPT_DIR
curl -s -L $NEWRELIC_URL | tar xz
cd newrelic-php5-${NEWRELIC_VERSION}-linux
cp -f agent/x64/newrelic-${ZEND_MODULE_API_VERSION}.so ${PHP_EXTENSION_DIR}/newrelic.so
