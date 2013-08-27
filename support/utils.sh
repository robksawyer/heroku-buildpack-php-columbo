
##
# Test an URL
#
# @param string $1 The URL to test
##
function is_valid_url() {
    echo "Testing URL: $1"
    if [  `curl --silent --head --location --insecure $1 | grep 200 | wc -l` = "0" ]; then
        echo "URL not found: $1"
        echo "Please update variables.sh with a valid url or version number for this package"
        exit 1
    fi
}

##
# Upload a file to S3
#
# @param string $1 The file name
##
function upload_to_s3() {
    s3cmd put --acl-public "$1" "s3://$BUILDPACK_S3_BUCKET/$1"

    # Retry the upload once if it fails
    if [ "$?" != "0" ] && [ -z "$2" ]; then
        echo "Upload failed, retrying upload..."
        upload_to_s3 "$1" "retry"
    elif [ ! -z "$2" ]; then
        echo "Upload failed"
        exit 1;
    fi
}

# Compare the md5 of the manifest file with the specified file
# Retrieved on 2012-11-17 from https://github.com/iphoting/heroku-buildpack-php-tyler/blob/master/bin/compile
# Modified by Jesse Patching <jesse@radpenguin.ca> for use in taeram/heroku-buildpack-php-columbo
function check_md5() {
    TARGET="$1"
    REMOTE_MD5SUM=`cat "${BUNDLE_DIR}/${MANIFEST_FILE}" | grep "${TARGET}" | cut -d ' ' -f 1`
    LOCAL_MD5SUM=`$MD5SUM_CMD ${BUNDLE_DIR}/${TARGET} | cut -d ' ' -f 1`
    ! [ "$REMOTE_MD5SUM" = "$LOCAL_MD5SUM" ]
}

# Indent the string
function indent() {
  sed -u 's/^/       /'
}
