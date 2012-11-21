#!/bin/bash

SUPPORT_DIR=`dirname $(readlink -f $0)`
BUILD_DIR=$SUPPORT_DIR/../build
CONFIG_FILE=$SUPPORT_DIR/config.sh

if [ ! -e $CONFIG_FILE ]; then
    echo "Cannot find $CONFIG_FILE, exiting..."
    exit 1;
fi

. $CONFIG_FILE

if [ -z "$S3_BUCKET" ]; then
    echo "\$S3_BUCKET variable not found, exiting..."
    exit 1;
fi

APACHE_VERSION=2.2.22
ANT_VERSION=1.8.4
PHP_VERSION=5.3.18
MANIFEST_FILE=manifest.md5sum
APACHE_TGZ=apache-${APACHE_VERSION}.tar.gz
ANT_TGZ=ant-${ANT_VERSION}.tar.gz
PHP_TGZ=php-${PHP_VERSION}.tar.gz
APP_TGZ=app-bundle.tar.gz

# Prepare for the build
[ -e $BUILD_DIR ]; rm -Rf $BUILD_DIR
mkdir $BUILD_DIR

# apache
cat > $BUILD_DIR/apache.sh << EOF
    curl -s -L http://www.apache.org/dist/httpd/httpd-${APACHE_VERSION}.tar.gz | tar zx
    cd httpd-${APACHE_VERSION}

    ./configure --prefix=/app/apache --enable-so --enable-rewrite --enable-deflate --enable-expires --enable-headers && \
    make && \
    make install

    echo "$APACHE_VERSION" > VERSION
EOF
chmod 755 $BUILD_DIR/apache.sh

# php
cat > $BUILD_DIR/php.sh << EOF
    curl -s -L http://us3.php.net/get/php-${PHP_VERSION}.tar.gz/from/us3.php.net/mirror | tar zx
    cd php-${PHP_VERSION}

    ./configure --prefix=/app/php --with-apxs2=/app/apache/bin/apxs  --with-config-file-path=/app/php \
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

    echo "$PHP_VERSION" > VERSION

    # php extensions
    mkdir /app/php/ext
    cp /usr/lib/libmysqlclient.so.16 /app/php/ext/

    # pear
    /app/php/bin/pear config-set php_dir /app/php
    echo "no" | /app/php/bin/pecl install apc

    # composer
    curl -L -s  https://getcomposer.org/installer | /app/php/bin/php
    mv composer.phar /app/php/bin/composer
EOF
chmod 755 $BUILD_DIR/php.sh

# Since Apache and PHP are dependent on each other and need to be built at the
# same time, we'll download the entire /app directory and re-package apache and
# php afterwards
vulcan build -s $BUILD_DIR/ -p /app/ -c "./apache.sh && ./php.sh" -o $APP_TGZ

# Extract the app bundle
tar xvf $APP_TGZ -C $BUILD_DIR/

# Upload Apache to S3
cd $BUILD_DIR/
tar zcf $APACHE_TGZ apache
s3cmd put --acl-public $APACHE_TGZ s3://$S3_BUCKET/$APACHE_TGZ

# Upload PHP to S3
tar zcf $PHP_TGZ php
s3cmd put --acl-public $PHP_TGZ s3://$S3_BUCKET/$PHP_TGZ

# Grab ant and upload to S3
curl -L -s http://apache.sunsite.ualberta.ca//ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz | tar zx
mv apache-ant-${ANT_VERSION} ant
tar zcf $ANT_TGZ ant
s3cmd put --acl-public $ANT_TGZ s3://$S3_BUCKET/$ANT_TGZ

# Update the manifest file
md5sum $APACHE_TGZ > $MANIFEST_FILE
md5sum $ANT_TGZ >> $MANIFEST_FILE
md5sum $PHP_TGZ >> $MANIFEST_FILE
s3cmd put --acl-public $MANIFEST_FILE s3://$S3_BUCKET/$MANIFEST_FILE
