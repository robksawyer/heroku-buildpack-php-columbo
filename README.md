Apache+PHP build pack
========================

This is a build pack bundling PHP and Apache for Heroku apps.


Configuration
-------------

The config files are bundled with the build pack itself:

* conf/httpd.conf
* conf/php.ini


Pre-compiling binaries
----------------------

    # Launch an Ubuntu 10.04 EC2 AMI
    # Preferred AMI: ami-68c01201

    # Install the development tools
    sudo su
    apt-get update
    apt-get -y install g++ gcc libssl-dev libpng-dev libjpeg-dev libxml2-dev libmysqlclient-dev libpq-dev libpcre3-dev php5-dev php-pear curl libcurl3 libcurl3-dev php5-curl libsasl2-dev

    # apache
    mkdir /app
    curl http://www.apache.org/dist/httpd/httpd-2.2.22.tar.gz | tar zx
    cd httpd-2.2.22
    ./configure --prefix=/app/apache --enable-rewrite --enable-deflate --enable-expires --enable-headers
    make && make install
    cd ..

    # php
    curl -L http://ca3.php.net/get/php-5.3.18.tar.gz/from/us1.php.net/mirror | tar zx
    cd php-5.3.18/
    ./configure --prefix=/app/php --with-apxs2=/app/apache/bin/apxs --with-mysql --with-pdo-mysql --with-pgsql --with-pdo-pgsql --with-iconv --with-gd --with-curl=/usr/lib --with-config-file-path=/app/php --enable-soap=shared --with-openssl
    make && make install
    cd ..

    # php extensions
    mkdir /app/php/ext
    cp /usr/lib/libmysqlclient.so.16 /app/php/ext/

    # pear
    apt-get install php5-dev php-pear
    pear config-set php_dir /app/php
    pecl install apc
    mkdir /app/php/include/php/ext/apc
    cp /usr/lib/php5/20090626/apc.so /app/php/ext/
    cp /usr/lib/php5/20090626/apc.so /app/php/lib/php/extensions/no-debug-non-zts-20090626/
    cp /usr/include/php5/ext/apc/apc_serializer.h /app/php/include/php/ext/apc/

    # package
    cd /app
    echo '2.2.22' > apache/VERSION
    tar cvf - apache | gzip -9 - > apache-2.2.22.tar.gz
    echo '5.3.18' > php/VERSION
    tar cvf - php | gzip -9 - > php-5.3.18.tar.gz


Hacking
-------

To change this buildpack, fork it on Github. Push up changes to your fork, then create a test app with --buildpack <your-github-url> and push to it.


Meta
----

Created by Pedro Belo.
Many thanks to Keith Rarick for the help with assorted Unix topics :)
