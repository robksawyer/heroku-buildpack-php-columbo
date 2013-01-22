#!/bin/bash

# fail fast
set -e

SCRIPT_DIR=`dirname $(readlink -f $0)`
. $SCRIPT_DIR/variables.sh

curl -s -L http://www.apache.org/dist/httpd/httpd-${APACHE_VERSION}.tar.gz | tar zx
cd httpd-${APACHE_VERSION}

./configure --prefix=/app/apache --enable-so --enable-rewrite --enable-deflate --enable-expires --enable-headers && \
make && \
make install

# Install mod macro
curl -s -L http://people.apache.org/~fabien/mod_macro/mod_macro-${APACHE_MOD_MACRO_VERSION}.tar.gz | tar zx
cd mod_macro-${APACHE_MOD_MACRO_VERSION}
/app/apache/bin/apxs -cia ./mod_macro.c

# Create the empty log files
mkdir -p /app/logs/
touch /app/logs/apache-error.log
touch /app/logs/apache-access.log

echo "$APACHE_VERSION" > VERSION
