#!/bin/bash

SUPPORT_DIR=`dirname $(readlink -f $0)`
BUILD_DIR=$SUPPORT_DIR/../build
CONFIG_FILE=$SUPPORT_DIR/../config.sh
VARIABLES_FILE=$SUPPORT_DIR/../variables.sh

if [ ! -e $CONFIG_FILE ]; then
    echo "Cannot find $CONFIG_FILE, exiting..."
    exit 1;
fi

. $CONFIG_FILE
. $VARIABLES_FILE

if [ -z "$S3_BUCKET" ]; then
    echo "\$S3_BUCKET variable not found in $CONFIG_FILE, exiting..."
    exit 1;
fi

if [ -z "$NEWRELIC_LICENSE_KEY" ]; then
    echo "\$NEWRELIC_LICENSE_KEY variable not found in $CONFIG_FILE, exiting..."
    exit 1;
fi

if [ -z `which s3cmd` ]; then
    echo "Cannot find s3cmd, please install it, exiting..."
    exit 1;
fi

S3CMD_HAS_ACCESS=`s3cmd ls s3://$S3_BUCKET 2>&1 > /dev/null`
if [ $? = "1" ]; then
    echo "s3cmd has not been setup with access to $S3_BUCKET."
    echo "Please run s3cmd --configure to set it up."
    echo "Exiting..."
    exit 1;
fi

APP_BUNDLE_TGZ_FILE=app-bundle.tar.gz

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

# new relic
cat > $BUILD_DIR/newrelic.sh << EOF
    curl -s -L http://download.newrelic.com/php_agent/archive/${NEWRELIC_VERSION}/newrelic-php5-${NEWRELIC_VERSION}-linux.tar.gz | tar zx
    cd newrelic-php5-${NEWRELIC_VERSION}-linux

    NR_INSTALL_PATH=/app/php/bin NR_INSTALL_KEY="$NEWRELIC_LICENSE_KEY" ./newrelic-install
EOF
chmod 755 $BUILD_DIR/newrelic.sh

# fail fast
set -e

# Since Apache and PHP are dependent on each other and need to be built at the
# same time, we'll download the entire /app directory and re-package apache and
# php afterwards
vulcan build -v -s $BUILD_DIR/ -p /app -c "./apache.sh && ./php.sh && ./newrelic.sh" -o $BUILD_DIR/$APP_BUNDLE_TGZ_FILE

# Extract the app bundle
cd $BUILD_DIR/
tar xvf $APP_BUNDLE_TGZ_FILE

# Upload Apache to S3
tar zcf $APACHE_TGZ_FILE apache
s3cmd put --acl-public $APACHE_TGZ_FILE s3://$S3_BUCKET/$APACHE_TGZ_FILE

# Upload PHP to S3
tar zcf $PHP_TGZ_FILE php
s3cmd put --acl-public $PHP_TGZ_FILE s3://$S3_BUCKET/$PHP_TGZ_FILE

# Grab ant and upload to S3
curl -L -s http://apache.sunsite.ualberta.ca//ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz | tar zx
mv apache-ant-${ANT_VERSION} ant
tar zcf $ANT_TGZ_FILE ant
s3cmd put --acl-public $ANT_TGZ_FILE s3://$S3_BUCKET/$ANT_TGZ_FILE

# Upload new relic to S3
#tar zcf $NEWRELIC_TGZ_FILE something-goes-here
#s3cmd put --acl-public $NEWRELIC_TGZ_FILE s3://$S3_BUCKET/$NEWRELIC_TGZ_FILE

# Update the manifest file
md5sum $APACHE_TGZ_FILE > $MANIFEST_FILE
md5sum $ANT_TGZ_FILE >> $MANIFEST_FILE
md5sum $PHP_TGZ_FILE >> $MANIFEST_FILE
md5sum $NEWRELIC_TGZ_FILE >> $MANIFEST_FILE
s3cmd put --acl-public $MANIFEST_FILE s3://$S3_BUCKET/$MANIFEST_FILE
