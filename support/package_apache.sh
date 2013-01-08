# fail fast
set -e

SCRIPT_DIR=`dirname $(readlink -f $0)`
. $SCRIPT_DIR/variables.sh

curl -s -L http://www.apache.org/dist/httpd/httpd-${APACHE_VERSION}.tar.gz | tar zx
cd httpd-${APACHE_VERSION}

./configure --prefix=/app/apache --enable-so --enable-rewrite --enable-deflate --enable-expires --enable-headers && \
make && \
make install

echo "$APACHE_VERSION" > VERSION
