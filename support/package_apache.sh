#!/bin/bash

# fail fast
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $SCRIPT_DIR/variables.sh

# pcre
echo "**** Downloading PCRE ${PCRE_VERSION}"
cd $SCRIPT_DIR
curl -s -L $PCRE_URL | tar zx
cd pcre-${PCRE_VERSION}
./configure --prefix=/app/apache/local/pcre && \
make && \
make install

# apache
echo "**** Downloading Apache ${APACHE_VERSION}"
cd $SCRIPT_DIR
curl -s -L $APACHE_URL | tar zx

echo "**** Downloading Apache APR ${APACHE_APR_VERSION}"
cd $SCRIPT_DIR
mkdir httpd-${APACHE_VERSION}/srclib/apr
cd httpd-${APACHE_VERSION}/srclib/apr
curl -s -L $APACHE_APR_URL | tar zx --strip-components=1

echo "**** Downloading Apache APR Util ${APACHE_APR_UTIL_VERSION}"
cd $SCRIPT_DIR
mkdir httpd-${APACHE_VERSION}/srclib/apr-util
cd httpd-${APACHE_VERSION}/srclib/apr-util
curl -s -L $APACHE_APR_UTIL_URL | tar zx --strip-components=1

echo "**** Downloading mod_fcgid ${APACHE_MOD_FCGID_VERSION}"
cd $SCRIPT_DIR/httpd-${APACHE_VERSION}
curl -s -L $APACHE_MOD_FCGID_URL | tar zx --strip-components=1

# Tell apache to pick up fcgid
cd $SCRIPT_DIR/httpd-${APACHE_VERSION}/
./buildconf

echo "**** Compiling apache"
cd $SCRIPT_DIR
cd httpd-${APACHE_VERSION}
./configure \
    --prefix=/app/apache \
    --enable-so \
    --enable-deflate \
    --enable-expires \
    --enable-fcgid \
    --enable-headers \
    --enable-rewrite \
    --with-included-apr \
    --with-pcre=/app/apache/local/pcre && \
make && \
make install

# Create the user config directory
mkdir /app/apache/conf.d/

# mod macro
echo "**** Downloading mod_macro ${APACHE_MOD_MACRO_VERSION}"
cd $SCRIPT_DIR
curl -s -L $APACHE_MOD_MACRO_URL | tar zx

echo "**** Compiling mod_macro"
cd mod_macro-${APACHE_MOD_MACRO_VERSION}
/app/apache/bin/apxs -cia ./mod_macro.c

# Create the empty log files
cd $SCRIPT_DIR
mkdir -p /app/logs/
touch /app/logs/apache-error.log
touch /app/logs/apache-access.log

echo "$APACHE_VERSION" > VERSION
