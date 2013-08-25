#!/bin/bash

# fail fast
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $SCRIPT_DIR/variables.sh

# apache
echo "**** Downloading Apache ${APACHE_VERSION}"
cd $SCRIPT_DIR
curl -s -L $APACHE_URL | tar zx

echo "**** Compiling apache"
cd httpd-${APACHE_VERSION}
./configure \
    --prefix=/app/apache \
    --enable-so \
    --enable-rewrite \
    --enable-deflate \
    --enable-expires \
    --enable-headers && \
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
