#!/bin/bash

### On any error the script will fail
set -xeo pipefail

### Install dependancy
export CLOUDSDK_CORE_DISABLE_PROMPTS=1
curl https://sdk.cloud.google.com | bash
source /home/travis/.bashrc
export PATH=/home/travis/google-cloud-sdk/bin:$PATH
gcloud components update kubectl
gcloud --version

### Authenticate to gcloud
export GOOGLE_APPLICATION_CREDENTIALS=/tmp/gce.json # ENV var used by kubectl
set +x
  echo ${GCE_JSON_KEY} > $GOOGLE_APPLICATION_CREDENTIALS
set -x
gcloud auth activate-service-account --key-file /tmp/gce.json

### Build and push container to GCR registry
docker build -t gcr.io/${GCE_PROJECT}/ci:${TRAVIS_BUILD_NUMBER} -f Dockerfile.upgrade_analyzer .
gcloud docker push gcr.io/${GCE_PROJECT}/ci:${TRAVIS_BUILD_NUMBER}

### Fetch GKE credential
gcloud container clusters get-credentials ${GKE_CLUSTER_NAME} --project ${GCE_PROJECT} --zone ${GCE_ZONE}

### Update 'deployment' object in GKE which trigger a rollout of the new images
kubectl set image deployment/upgrade-analyzer-deployment upgrade-analyzer=gcr.io/${GCE_PROJECT}/ci:${TRAVIS_BUILD_NUMBER}
