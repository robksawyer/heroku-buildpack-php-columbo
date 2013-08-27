#!/bin/bash

# fail fast
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $SCRIPT_DIR/variables.sh

# new relic daemon
echo "**** Downloading New Relic ${NEWRELIC_VERSION}"
cd $SCRIPT_DIR
curl -s -L $NEWRELIC_URL | tar zx

cd newrelic-php5-${NEWRELIC_VERSION}-linux
mkdir -p /app/newrelic/bin /app/run
cp -f ./daemon/newrelic-daemon.x64 /app/newrelic/bin/newrelic-daemon

# Create the empty log files
cd $SCRIPT_DIR
mkdir -p /app/logs/
touch /app/logs/newrelic-php_agent.log
touch /app/logs/newrelic-daemon.log

echo "$NEWRELIC_VERSION" > /app/newrelic/VERSION
