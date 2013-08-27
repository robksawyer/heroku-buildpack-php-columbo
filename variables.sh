APACHE_VERSION="2.4.6"    # http://httpd.apache.org/download.cgi
APACHE_URL="http://www.apache.org/dist/httpd/httpd-${APACHE_VERSION}.tar.gz"
APACHE_APR_VERSION="1.4.8"    # http://apr.apache.org/download.cgi
APACHE_APR_URL="http://mirror.csclub.uwaterloo.ca/apache/apr/apr-${APACHE_APR_VERSION}.tar.gz"
APACHE_APR_UTIL_VERSION="1.5.2"    # http://httpd.apache.org/download.cgi
APACHE_APR_UTIL_URL="http://mirror.csclub.uwaterloo.ca/apache/apr/apr-util-${APACHE_APR_UTIL_VERSION}.tar.gz"
APACHE_MOD_FCGID_VERSION="2.3.7"
APACHE_MOD_FCGID_URL="http://apache.sunsite.ualberta.ca//httpd/mod_fcgid/mod_fcgid-${APACHE_MOD_FCGID_VERSION}.tar.gz"
APACHE_MOD_MACRO_VERSION="1.2.1"    # http://people.apache.org/~fabien/mod_macro/
APACHE_MOD_MACRO_URL="http://people.apache.org/~fabien/mod_macro/mod_macro-${APACHE_MOD_MACRO_VERSION}.tar.gz"
APACHE_TGZ_FILE="apache-${APACHE_VERSION}.tar.gz"
PCRE_VERSION="8.33"
PCRE_URL="http://sourceforge.net/projects/pcre/files/pcre/8.33/pcre-${PCRE_VERSION}.tar.gz/download"

ANT_VERSION="1.9.2"    # http://ant.apache.org/bindownload.cgi
ANT_URL="http://apache.sunsite.ualberta.ca/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz"
ANT_CONTRIB_VERSION="1.0b3"    # http://ant-contrib.sourceforge.net/
ANT_CONTRIB_URL="http://sourceforge.net/projects/ant-contrib/files/ant-contrib/${ANT_CONTRIB_VERSION}/ant-contrib-${ANT_CONTRIB_VERSION}-bin.tar.gz/download"
ANT_TGZ_FILE="ant-${ANT_VERSION}.tar.gz"

PHP_VERSION="5.4.19"    # http://php.net/downloads.php
PHP_URL="http://us3.php.net/get/php-${PHP_VERSION}.tar.gz/from/us3.php.net/mirror"

LIBMCRYPT_VERSION="2.5.8"    # http://sourceforge.net/projects/mcrypt/files/Libmcrypt/
LIBMCRYPT_URL="http://sourceforge.net/projects/mcrypt/files/Libmcrypt/${LIBMCRYPT_VERSION}/libmcrypt-${LIBMCRYPT_VERSION}.tar.bz2/download"
LIBMEMCACHED_VERSION="1.0.16"    # http://libmemcached.org/libMemcached.html
LIBMEMCACHED_URL="https://launchpad.net/libmemcached/1.0/${LIBMEMCACHED_VERSION}/+download/libmemcached-${LIBMEMCACHED_VERSION}.tar.gz"
MEMCACHED_VERSION="2.1.0"    # http://pecl.php.net/package/memcached
MEMCACHED_URL="http://pecl.php.net/get/memcached-${MEMCACHED_VERSION}.tgz"
PHP_TGZ_FILE="php-${PHP_VERSION}.tar.gz"

NEWRELIC_VERSION="3.7.5.7"    # http://download.newrelic.com/php_agent/release/
NEWRELIC_TGZ_FILE="newrelic-php5-${NEWRELIC_VERSION}-linux.tar.gz"

COMPOSER_URL="https://getcomposer.org/installer"

NEWRELIC_VERSION="3.7.5.7"    # http://download.newrelic.com/php_agent/release/
NEWRELIC_URL="http://download.newrelic.com/php_agent/archive/${NEWRELIC_VERSION}/newrelic-php5-${NEWRELIC_VERSION}-linux.tar.gz"
NEWRELIC_TGZ_FILE="newrelic-${NEWRELIC_VERSION}.tar.gz"

MANIFEST_FILE="manifest.md5sum"

# Detect which md5sum command to use
MD5SUM_CMD=md5sum
if [ "$OSTYPE" == "darwin12" ]; then
    MD5SUM_CMD=gmd5sum
fi

if [ -z `which $MD5SUM_CMD` ]; then
    echo "Cannot find \"$MD5SUM_CMD\" command. Please verify that the coreutils package is installed"
    echo "For more information, see the README.md"
fi
