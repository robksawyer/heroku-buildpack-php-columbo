Apache+PHP build pack
========================

This is a build pack bundling PHP, NodeJS and Apache for Heroku apps.

Apache comes with the following modules installed:
* deflate
* expires
* headers
* rewrite

Along with PHP, [Composer](http://getcomposer.org) and [Apache Ant](http://ant.apache.org/)
are included.

Configuration
-------------

The config files are bundled with the build pack itself:
* conf/httpd.conf
* conf/php.ini

Pre-compiling binaries
----------------------

### First time setup

On your local development machine:

    # Install Amazon S3 command line tools
    sudo apt-get -y install s3cmd

    # If you haven't already, sign up for an Amazon S3 account
    # Go to your Account page, and click Security Credentials
    # Grab your Access Key ID and Secret Access Key
    s3cmd --configure
        # Enter your Access Key and Secret Key when asked
        # When asked if you want to Save Settings, answer Yes

    # Create an S3 bucket for your buildpack assets
    s3cmd mb s3://<bucket_name>

    # Create and launch a build server
    gem install vulcan
    vulcan create [NAME]

### Build the packages

On your local development machine:

    APACHE_VERSION=2.2.22
    ANT_VERSION=1.8.4
    PHP_VERSION=5.3.18
    S3_BUCKET=<bucket_name>     # Change this to your S3 bucket

    MANIFEST_FILE=manifest.md5sum
    APACHE_TGZ=apache-${APACHE_VERSION}.tar.gz
    ANT_TGZ=ant-${ANT_VERSION}.tar.gz
    PHP_TGZ=php-${PHP_VERSION}.tar.gz
    APP_TGZ=app-bundle.tar.gz

    # Prepare for the build
    rm -Rf build
    mkdir build

    # apache
    cat > build/apache.sh << EOF
        curl -s -L http://www.apache.org/dist/httpd/httpd-${APACHE_VERSION}.tar.gz | tar zx
        cd httpd-${APACHE_VERSION}

        ./configure --prefix=/app/apache --enable-so --enable-rewrite --enable-deflate --enable-expires --enable-headers && \
        make && \
        make install

        echo "$APACHE_VERSION" > VERSION
    EOF
    chmod 755 build/apache.sh

    # php
    cat > build/php.sh << EOF
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
    chmod 755 build/php.sh

    # Since Apache and PHP are dependent on each other and need to be built at the
    # same time, we'll download the entire /app directory and re-package apache and
    # php afterwards
    vulcan build -s build/ -p /app/ -c "./apache.sh && ./php.sh" -o $APP_TGZ

    # Extract the app bundle
    tar xvf $APP_TGZ -C build/

    # Upload Apache to S3
    cd build/
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

Hacking
-------

To change this buildpack, fork it on Github. Push up changes to your fork, then create a test app with --buildpack <your-github-url> and push to it.

Meta
----

Created by Pedro Belo.
Many thanks to Keith Rarick for the help with assorted Unix topics :)
