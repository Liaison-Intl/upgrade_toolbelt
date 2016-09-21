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
docker build -t gcr.io/<google-project>/ci:<build-number> -f Dockerfile.upgrade_analyzer .

### Publish the container to GCE:
gcloud docker push gcr.io/<google-project>/ci:<build-number>

### Point to GKE cluster
gcloud container clusters get-credentials <GKE-cluster-name> \
    --zone <google-cloud-zone> --project <google-project>

### Create and store the secret on GKE -- only need to be done once
kubectl create secret generic upgrade-analyzer-secrets --from-literal=github-token=YOUR_GITHUB_TOKEN

### Deploy declaratively -- first time
kubectl create -f kubectl_config/upgrade-analyzer-deployment.yml
kubectl edit deployment/upgrade-analyzer-deployment
# ^^ replace NAME_OF_REPO with with the repo you want to monitor

### Deploy declaratively -- when already exist
kubectl set image deployment/upgrade-analyzer-deployment \
  upgrade-analyzer=gcr.io/<google-project>/ci:<build-number>
# ^^ deploy will not occur if you don't set a new image build-number
#    if you want to force a pods recreation with same ci:<buildnumber>
#    simply delete the running pods with 'kubectl delete pods POD_NAME'
#    the replication controller will automatically recreate a new one

### Previous way to deploy imperatively
kubectl delete deployment upgrade-analyzer-deployment
kubectl run upgrade-analyzer-deployment \
  --image=gcr.io/<google-project>/ci:<build-number> --command \
  -- /opt/ci/bin/upgrade_analyzer --listen --repo=REPO --token=GITHUB_TOKEN

### Useful kubernetes commands
kubectl get pods
kubectl get deployments
kubectl get secrets
kubectl logs PODS_NAME
kubectl exec -it PODS_NAME -- sh
kubectl run -i --tty test --image=gcr.io/<google-project>/ci:<build-number> -- sh
kubectl delete deployment NAME_OF_DEPLOYMENT
kubectl describe secret/upgrade-analyzer-secrets
kubectl get secret upgrade-analyzer-secrets -o yaml  # secrets show as base64
kubectl config view
kubectl proxy
kubectl cluster-info # see URI for kubernetes-dashboard
# ^^  See your google cloud console for the credential of the GKE cluster

### External Documentation

https://help.github.com/articles/creating-an-access-token-for-command-line-use/
https://cloud.google.com/container-engine/docs/quickstart
https://github.com/travis-ci/travis.rb#table-of-contents
http://octokit.github.io/octokit.rb/Octokit.html
http://kubernetes.io/docs/user-guide/secrets/
http://kubernetes.io/docs/
https://developers.google.com/console/help/new/#serviceaccounts
https://cloud.google.com/container-registry/docs/advanced-authentication
https://docs.travis-ci.com/user/customizing-the-build
https://docs.travis-ci.com/user/deployment/script/

### Alternate way to authenticate to GKE/GCR 
# ( for CI integration purpose where gcloud sdk is not available )
docker login -u _json_key -p="${GCE_JSON_KEY}" https://gcr.io
docker push gcr.io/${GCE_PROJECT}/ci:${TRAVIS_BUILD_NUMBER}
kubectl config set-credentials default --username=${GKE_USERNAME} --password=${GKE_PASSWORD}
kubectl config set-cluster default --server=http://${GKE_SERVER} --insecure-skip-tls-verify=true
kubectl config set-context default --cluster=default --user=default
kubectl config use-context default

## Developer setup

### Linux

Install Docker and look at the Docker instructions.

### OS X

Get Docker for Mac and look at the Docker instructions.

## development on the upgrade-analyzer

### Use docker compose
echo GITHUB_TOKEN=YOUR_GITHUB_TOKEN > kv.conf
echo REPO=NAME_OF_REPO >> kv.conf
docker-compose up
# ^^ Use the CI container as a runtime with your local directory mounted
#    inside the container so that the code in this directory is used live.
#    allow to develop in the exact same env in which the code will run.

### other usefull docker-compose command
docker-compose run ci sh      # overide startup of app container
                              # to run sh interactivelly.
docker-compose run ci bundle exec rails c

docker-compose ps             # see listing of all the containers running
                              # and there status

docker-compose down           # Stop all container

docker-compose build          # Trigger a build of all container
                              # to be used each time you modify Dockerfile
docker-compose up --build     # ... idem, also trigger a 'up' action

### Docker for the upgrade_toolbelt

    host$ docker build -t upgrade_toolbelt .
    host$ docker run --rm --env 'UTB_OWNER_AND_REPO=benjaminoakes/maid' --env 'UTB_JOB_COUNT=11' -v "$PWD:/opt" -v "$HOME/var/ci":/var/ci -i -t upgrade_toolbelt sh -l
    container$ utb-build-analyze 407
