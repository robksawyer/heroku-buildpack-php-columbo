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

# Create the empty log files
mkdir -p /app/logs/
touch /app/logs/apache-error.log
touch /app/logs/apache-access.log

echo "$APACHE_VERSION" > VERSION
