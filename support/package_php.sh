# fail fast
set -e

SCRIPT_DIR=`dirname $(readlink -f $0)`
. $SCRIPT_DIR/variables.sh

curl -s -L http://us3.php.net/get/php-${PHP_VERSION}.tar.gz/from/us3.php.net/mirror | tar zx
cd php-${PHP_VERSION}

./configure --prefix=/app/php --with-apxs2=/app/apache/bin/apxs  --with-config-file-path=/app/php \
    --with-config-file-scan-dir=/app/php/conf.d \
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

# php extensions
mkdir /app/php/ext
cp /usr/lib/libmysqlclient.so.16 /app/php/ext/

# pear
/app/php/bin/pear config-set php_dir /app/php
echo "no" | /app/php/bin/pecl install apc
cp $SCRIPT_DIR/conf/apc.ini /app/php/conf.d/apc.ini

# new relic
cd $SCRIPT_DIR
curl -L "http://download.newrelic.com/php_agent/archive/${NEWRELIC_VERSION}/newrelic-php5-${NEWRELIC_VERSION}-linux.tar.gz" | tar xz
cd newrelic-php5-${NEWRELIC_VERSION}-linux
cp -f agent/x64/newrelic-`/app/php/bin/phpize --version | grep "Zend Module Api No" | tr -d ' ' | cut -f 2 -d ':'`.so /app/php/ext/
cp $SCRIPT_DIR/conf/newrelic.ini /app/php/conf.d/newrelic.ini
