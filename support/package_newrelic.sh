#!/bin/bash

# fail fast
set -e

SCRIPT_DIR=`dirname $(readlink -f $0)`
. $SCRIPT_DIR/variables.sh

curl -s -L http://download.newrelic.com/php_agent/archive/${NEWRELIC_VERSION}/newrelic-php5-${NEWRELIC_VERSION}-linux.tar.gz | tar zx
cd newrelic-php5-${NEWRELIC_VERSION}-linux

mkdir -p /app/newrelic/bin /app/newrelic/etc /app/newrelic/var/run
cp -f ./daemon/newrelic-daemon.x64 /app/newrelic/bin/newrelic-daemon
cp $SCRIPT_DIR/conf/newrelic.cfg /app/newrelic/etc/newrelic.cfg

# Create the empty log files
mkdir -p /app/logs/
touch /app/logs/newrelic-php_agent.log
touch /app/logs/newrelic-daemon.log

echo "$NEWRELIC_VERSION" > /app/newrelic/VERSION
