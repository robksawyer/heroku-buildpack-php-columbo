#!/bin/bash

# fail fast
set -e

SCRIPT_DIR=`dirname $(readlink -f $0)`
. $SCRIPT_DIR/variables.sh

# mcrypt
curl -s -L "http://sourceforge.net/projects/mcrypt/files/Libmcrypt/${LIBMCRYPT_VERSION}/libmcrypt-${LIBMCRYPT_VERSION}.tar.bz2/download" -o - | tar xj

cd libmcrypt-$LIBMCRYPT_VERSION
./configure \
--prefix=/app/php/local \
--disable-rpath && \
make install

# php
cd $SCRIPT_DIR
curl -s -L http://us3.php.net/get/php-${PHP_VERSION}.tar.gz/from/us3.php.net/mirror | tar zx
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
    --with-zlib  && \
make && \
make install

# create the php config scan dir
mkdir /app/php/conf.d/

echo "$PHP_VERSION" > VERSION

# composer
curl -L -s  https://getcomposer.org/installer | /app/php/bin/php
mv composer.phar /app/php/bin/composer

# php shared libraries
mkdir /app/php/ext
cp /usr/lib/libmysqlclient.so.16 /app/php/ext/

# apc
/app/php/bin/pear config-set php_dir /app/php
echo "no" | /app/php/bin/pecl install apc

# libmemcached
curl --insecure -s -L "https://launchpad.net/libmemcached/1.0/${LIBMEMCACHED_VERSION}/+download/libmemcached-${LIBMEMCACHED_VERSION}.tar.gz" -o - | tar xz

cd libmemcached-${LIBMEMCACHED_VERSION}
./configure --prefix=/app/php/local && \
 make install

# memcached
curl -s -L "http://pecl.php.net/get/memcached-${MEMCACHED_VERSION}.tgz" -o - | tar xz

cd memcached-${MEMCACHED_VERSION}
sed -i -e '18 s/no, no/yes, yes/' ./config.m4 # Enable memcached json serializer support: YES
sed -i -e '21 s/no, no/yes, yes/' ./config.m4 # Disable memcached sasl support: YES
/app/php/bin/phpize && \
./configure --with-libmemcached-dir=/app/php/local/ --prefix=/app/php --with-php-config=/app/php/bin/php-config && \
make && \
make install

# new relic
ZEND_MODULE_API_VERSION=`/app/php/bin/phpize --version | grep "Zend Module Api No" | tr -d ' ' | cut -f 2 -d ':'`
PHP_EXTENSION_DIR=`/app/php/bin/php-config --extension-dir`

cd $SCRIPT_DIR
curl -s -L "http://download.newrelic.com/php_agent/archive/${NEWRELIC_VERSION}/newrelic-php5-${NEWRELIC_VERSION}-linux.tar.gz" | tar xz
cd newrelic-php5-${NEWRELIC_VERSION}-linux
cp -f agent/x64/newrelic-${ZEND_MODULE_API_VERSION}.so ${PHP_EXTENSION_DIR}/newrelic.so
