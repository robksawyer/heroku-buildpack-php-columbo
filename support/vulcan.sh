#!/bin/bash

# fail fast
set -e

SUPPORT_DIR=`dirname $(readlink -f $0)`
BUILD_DIR=$SUPPORT_DIR/../build
CONF_DIR=$SUPPORT_DIR/../conf/
VULCAN_CONFIG_FILE=$SUPPORT_DIR/config.sh
VARIABLES_FILE=$SUPPORT_DIR/../variables.sh
APP_BUNDLE_TGZ_FILE=app-bundle.tar.gz

if [ ! -e $VULCAN_CONFIG_FILE ]; then
    echo "Cannot find $VULCAN_CONFIG_FILE, exiting..."
    exit 1;
fi

. $VARIABLES_FILE
. $VULCAN_CONFIG_FILE

if [ -z "$BUILDPACK_S3_BUCKET" ]; then
    echo "\$BUILDPACK_S3_BUCKET variable not found in $VULCAN_CONFIG_FILE, exiting..."
    exit 1;
fi

if [ -z `which s3cmd` ]; then
    echo "Cannot find s3cmd, please install it, exiting..."
    exit 1;
fi

S3CMD_HAS_ACCESS=`s3cmd ls s3://$BUILDPACK_S3_BUCKET 2>&1 > /dev/null`
if [ $? = "1" ]; then
    echo "s3cmd has not been setup with access to $BUILDPACK_S3_BUCKET."
    echo "Please run s3cmd --configure to set it up."
    echo "Exiting..."
    exit 1;
fi

# Prepare for the build
[ -e $BUILD_DIR ]; rm -Rf $BUILD_DIR
mkdir $BUILD_DIR

# Copy the config dir so it's accessible during the build process
cp -r $CONF_DIR $BUILD_DIR/conf

# Copy the variables
cp $VARIABLES_FILE $BUILD_DIR/variables.sh

# Copy the package scripts
cp $SUPPORT_DIR/package_apache.sh $BUILD_DIR/
cp $SUPPORT_DIR/package_php.sh $BUILD_DIR/
cp $SUPPORT_DIR/package_newrelic.sh $BUILD_DIR/

# Since Apache and PHP are dependent on each other and need to be built at the
# same time, we'll download the entire /app directory and re-package afterwards
vulcan build -v -s $BUILD_DIR/ -p /app -c "./package_apache.sh && ./package_php.sh && ./package_newrelic.sh" -o $BUILD_DIR/$APP_BUNDLE_TGZ_FILE

echo -n "Did build succeed? (Y/n)"
read IS_SUCCESSFUL
if [ "$IS_SUCCESSFUL" = "n" ] || [ "$IS_SUCCESSFUL" = "N" ]; then
    echo "Exiting..."
    exit 1;
fi

# Extract the app bundle
echo "Extracting app bundle"
cd $BUILD_DIR/
tar xf $APP_BUNDLE_TGZ_FILE

# Upload Apache to S3
tar zcf $APACHE_TGZ_FILE apache logs/apache*
s3cmd put --acl-public $APACHE_TGZ_FILE s3://$BUILDPACK_S3_BUCKET/$APACHE_TGZ_FILE

# Upload PHP to S3
tar zcf $PHP_TGZ_FILE php
s3cmd put --acl-public $PHP_TGZ_FILE s3://$BUILDPACK_S3_BUCKET/$PHP_TGZ_FILE

# Grab ant and upload to S3
curl -L -s http://apache.sunsite.ualberta.ca//ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz | tar zx
mv apache-ant-${ANT_VERSION} ant
tar zcf $ANT_TGZ_FILE ant
s3cmd put --acl-public $ANT_TGZ_FILE s3://$BUILDPACK_S3_BUCKET/$ANT_TGZ_FILE

# Upload new relic to S3
tar zcf $NEWRELIC_TGZ_FILE newrelic logs/newrelic*
s3cmd put --acl-public $NEWRELIC_TGZ_FILE s3://$BUILDPACK_S3_BUCKET/$NEWRELIC_TGZ_FILE

# Update the manifest file
md5sum $APACHE_TGZ_FILE > $MANIFEST_FILE
md5sum $ANT_TGZ_FILE >> $MANIFEST_FILE
md5sum $PHP_TGZ_FILE >> $MANIFEST_FILE
md5sum $NEWRELIC_TGZ_FILE >> $MANIFEST_FILE
s3cmd put --acl-public $MANIFEST_FILE s3://$BUILDPACK_S3_BUCKET/$MANIFEST_FILE
