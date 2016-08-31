# rails_upgrade_analyzer
Runs a process that watches for Travis builds to finish and inspects the results to ensure it doesn't make the Rails 4 build worse.

# Deploying a new version
There are probably better ways of doing this. This is a work in progress.

## Build the container with a new version number (v2):
sudo docker build -t gcr.io/rails-upgrade-analyzer/ci:v2 -f lib/ci/Dockerfile .

## Publish the container to GCE:
sudo gcloud docker push gcr.io/rails-upgrade-analyzer/ci:v2

## Deploy the container:
kubectl delete deployment rails-upgrade-analyzer
kubectl run rails-upgrade-analyzer --image=gcr.io/rails-upgrade-analyzer/ci:v3 --env="GITHUB_TOKEN=ABC123"

# External Documentation

https://help.github.com/articles/creating-an-access-token-for-command-line-use/
https://cloud.google.com/container-engine/docs/quickstart
https://github.com/travis-ci/travis.rb#table-of-contents
http://octokit.github.io/octokit.rb/Octokit.html

