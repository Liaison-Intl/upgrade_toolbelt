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
sudo docker build -t gcr.io/wa-qa-1087/ci:v5 -f Dockerfile.upgrade_analyzer .

### Publish the container to GCE:
sudo gcloud docker push gcr.io/wa-qa-1087/ci:v5

### Deploy the container:
gcloud container clusters get-credentials utilities --zone us-east1-d --project wa-qa-1087

### New way to deploy declaratively -- first time
kubectl create -f kubectl_config/upgrade-analyzer-deployment

### New way to deploy declaratively -- when already exist
kubectl replace -f kubectl_config/upgrade-analyzer-deployment

### Previous way to deploy imperatively
#kubectl delete deployment rails-upgrade-analyzer
#kubectl run rails-upgrade-analyzer --image=gcr.io/wa-qa-1087/ci:v5 --command -- /opt/ci/bin/upgrade_analyzer --listen --repo=REPO --token=GITHUB_TOKEN

### Useful kubernetes commands
kubectl get pods
kubectl logs PODS_NAME
kubectl exec -it PODS_NAME -- sh

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
