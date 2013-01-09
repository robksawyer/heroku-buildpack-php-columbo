PHP build pack
========================

This is a Heroku build pack which bundles:
* [Ant](http://ant.apache.org/)
* [Apache](http://apache.org), with the following modules:
 * deflate
 * expires
 * headers
 * rewrite
* [Composer](http://getcomposer.org)
* [PHP](http://php.net/)
* [NPM](https://npmjs.org/)

This build pack should be used with [taeram/heroku-buildpack-php-columbo-template](https://github.com/taeram/heroku-buildpack-php-columbo-template).

Configuration
-------------

The config files are bundled with the build pack itself:
* conf/httpd.conf
* conf/php.ini

Pre-compiling binaries
----------------------

### First time setup

On your local development machine:
```bash
# Install Amazon S3 command line tools
sudo apt-get -y install s3cmd

# If you haven't already, sign up for an Amazon S3 account
# Go to your Account page, and click Security Credentials
# Grab your Access Key ID and Secret Access Key
s3cmd --configure
    # Enter your Access Key and Secret Key when asked
    # When asked if you want to Save Settings, answer Yes

# Create an S3 bucket for your buildpack assets
s3cmd mb s3://[bucket_name]

# Create and launch a build server
sudo gem install vulcan
vulcan create [NAME]
```

### Build the buildpack

On your local development machine:
* Create `./config.sh` and add your S3 bucket name to it:

```bash
S3_BUCKET=[bucket_name]
```

* Run `./support/vulcan.sh`

Hacking
-------

To change this buildpack, fork it on Github. Push up changes to your fork, then create a test app with --buildpack <your-github-url> and push to it.

Meta
----

Created by Pedro Belo.
Many thanks to Keith Rarick for the help with assorted Unix topics :)
