Columbo PHP build pack
========================

This is a Heroku build pack which includes:
* [Ant](http://ant.apache.org/)
* [Apache](http://apache.org), including the following modules:
 * deflate
 * expires
 * headers
 * macro
 * rewrite
* [Composer](http://getcomposer.org)
* [New Relic](http://newrelic.com/)
* [NPM](https://npmjs.org/)
* [PHP](http://php.net/), including the following notable extensions:
 * apc
 * curl
 * mcrypt
 * memcache
 * mysql
 * mysqli
 * newrelic
 * pdo
 * pgsql
 * phar
 * soap
 * zip

This build pack should be used with [taeram/heroku-buildpack-php-columbo-template](https://github.com/taeram/heroku-buildpack-php-columbo-template).

Configuration
-------------

The Apache, PHP, PHP Extension and New Relic config files are bundled with the
build pack itself, and can be found in the conf/ directory.

Pre-compiling binaries
----------------------

### First time setup

On your local development machine, create an Amazon S3 bucket to hold your buildpack assets:
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
```

Create and launch a build server:
```
sudo gem install vulcan
vulcan create [NAME]
```

### Build the buildpack

On your local development machine:
* Create `./support/config.sh` and add your S3 bucket name to it:

```bash
BUILDPACK_S3_BUCKET=[bucket_name]
```

* Run `./support/vulcan.sh apache ant php newrelic`

Hacking
-------

To change this buildpack, fork it on Github. Push up changes to your fork, then create a test app with --buildpack <your-github-url> and push to it.

Meta
----

This repo is a fork of [heroku/heroku-buildpack-php](https://github.com/heroku/heroku-buildpack-php),
and includes code from [heroku/heroku-buildpack-nodejs](https://github.com/heroku/heroku-buildpack-nodejs)
and [heroku-buildpack-php-tyler](https://github.com/iphoting/heroku-buildpack-php-tyler).
