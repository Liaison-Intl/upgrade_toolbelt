# Upgrade Toolbelt

Utilities to help upgrading a ~250K line Rails app.

## Features

* Travis CI log downloading
* Log parsing for...
  * Deprecation notices
  * Rails tests
  * Jasmine specs

## Pull Request Analyzer

Runs a process that watches for Travis builds to finish and inspects the results to ensure it doesn't make the Rails 4 build worse.

### Deploying a new version
There are probably better ways of doing this. This is a work in progress.

### Build the container with a new version number (v2):
sudo docker build -t gcr.io/rails-upgrade-analyzer/ci:v2 -f lib/ci/Dockerfile.upgrade_analyzer .

### Publish the container to GCE:
sudo gcloud docker push gcr.io/rails-upgrade-analyzer/ci:v2

### Deploy the container:
kubectl delete deployment rails-upgrade-analyzer
kubectl run rails-upgrade-analyzer --listen --repo=REPO --token=GITHUB_TOKEN --image=gcr.io/rails-upgrade-analyzer/ci:v3

### External Documentation

https://help.github.com/articles/creating-an-access-token-for-command-line-use/
https://cloud.google.com/container-engine/docs/quickstart
https://github.com/travis-ci/travis.rb#table-of-contents
http://octokit.github.io/octokit.rb/Octokit.html

## Developer setup

### Linux

Install Docker and look at the Docker instructions.

### OS X

Get Docker for Mac and look at the Docker instructions.

### Docker

    host$ docker build -t upgrade_toolbelt .
    host$ docker run --rm --env 'UTB_OWNER_AND_REPO=benjaminoakes/maid' --env 'UTB_JOB_COUNT=11' -v "$PWD:/opt" -v "$HOME/var/ci":/var/ci -i -t upgrade_toolbelt sh -l
    container$ utb-build-analyze 407
