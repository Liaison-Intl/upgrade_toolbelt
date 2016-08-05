# Upgrade Toolbelt

Utilities to help upgrading a ~250K line Rails app.

## Features

* Travis CI log downloading
* Log parsing for...
  * Deprecation notices
  * Rails tests
  * Jasmine specs

## Developer setup

### Linux

Install Docker and look at the Docker instructions.

### OS X

Get Docker for Mac and look at the Docker instructions.

### Docker

    docker build -t upgrade_toolbelt .
    docker run --rm -v "$PWD:/opt" -v "$HOME/var/ci":/var/ci -i -t upgrade_toolbelt sh -l
