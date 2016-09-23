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

## Developer setup

### Linux

Install Docker and look at the Docker instructions.

### OS X

Get Docker for Mac and look at the Docker instructions.
https://docs.docker.com/docker-for-mac/

## development on the upgrade-analyzer

### What you will need

A GITHUB TOKEN - you can generate a token from your github account page
                 in the sections 'Personal Access Token'
                 The token will need repos and notification scope check

A github REPO you want to monitor with the upgrade-analyzer


### Use docker compose

echo GITHUB_TOKEN=YOUR_GITHUB_TOKEN > kv.conf
echo REPO=NAME_OF_REPO >> kv.conf

docker-compose up
# ^^ Use the CI container as a runtime with your local directory mounted
#    inside the container so that the code in this directory is used live.
#    allow to develop in the exact same env in which the code will run.
docker-compose up -d          # same as 'up' but run in the background

### other usefull docker-compose command
docker-compose run ci sh      # overide startup of app container
                              # to run sh interactivelly.
docker-compose run ci bundle exec rails c

docker-compose exec ci sh     # attach to an existing container named ci
                              # and run the sh into it

docker-compose ps             # see listing of all the containers running
                              # and there status

docker-compose down           # Stop all container

docker-compose build          # Trigger a build of all container
                              # to be used each time you modify Dockerfile
docker-compose up --build     # ditto but, also trigger a 'up' action

# Deploying a new version

## Deploy manually to kubernetes ( for reference only )

At this point travis is configured for continuous deployment
Each new build of branch 'master' triggers a deploy to google
container engine ( aka GKE ).

See .travis.xml and travis/continuous_deployment

### Install gcloud SDK
https://cloud.google.com/sdk/docs/quickstart-mac-os-x

### Install kubectl
gcloud components update kubectl

### Point to GKE cluster
gcloud container clusters get-credentials <GKE-cluster-name> \
    --zone <google-cloud-zone> --project <google-project>

You can visualize your kubectl config with 'kubectl config view'
to see how kubectl config was updated to point to your cluster.
Alternatively you could fetch the info manually from the cloud.google.com
and use 'kubectl set' to create that config.

### Build the container and assign it a tag containing a unique build-number
docker build -t gcr.io/<google-project>/ci:<build-number> -f Dockerfile.upgrade_analyzer .

### Push your local container to GCE so it can be consumed by Kubernetes
gcloud docker push gcr.io/<google-project>/ci:<build-number>

### Create and store the secret on GKE -- initial setup only
kubectl create secret generic upgrade-analyzer-secrets --from-literal=github-token=YOUR_GITHUB_TOKEN

### Deploy declaratively -- initial setup only
kubectl create -f kubectl_config/upgrade-analyzer-deployment.yml
kubectl edit deployment/upgrade-analyzer-deployment
# ^^ replace __REPO_NAME__ with with the repo you want to monitor
#    replace __GOOGLE_PROJECT__ with the name of your GCE project name
#    replace __BUILD_NUMBER__ with the build-number tagged container you
                              just pushed

### Confirm pods is healthy
kubectl get pods
# ^^ make sure pod is 'running'
kubectl edit deployment/upgrade-analyzer-deployment
# ^^ make sure were running intended version

### Deploy declaratively -- way to deploy after initial deploy
kubectl set image deployment/upgrade-analyzer-deployment \
  upgrade-analyzer=gcr.io/<google-project>/ci:<build-number>
# ^^ deploy will not occur if you don't set a new image build-number
#    if you want to force a pods recreation with same ci:<buildnumber>
#    simply delete the running pods with 'kubectl delete pods POD_NAME'
#    the replication controller will automatically recreate a new one

### Previous (blunt) way to deploy imperatively ( reference only )
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
https://deis.com/blog/2016/kubernetes-illustrated-guide/?imm_mid=0e520d&cmp=em-prog-na-na-newsltr_20160625

### Alternate way to authenticate to GKE/GCR
# ( for CI integration purpose where gcloud sdk is not available )
docker login -u _json_key -p="${GCE_JSON_KEY}" https://gcr.io
docker push gcr.io/${GCE_PROJECT}/ci:${TRAVIS_BUILD_NUMBER}
kubectl config set-credentials default --username=${GKE_USERNAME} --password=${GKE_PASSWORD}
kubectl config set-cluster default --server=http://${GKE_SERVER} --insecure-skip-tls-verify=true
kubectl config set-context default --cluster=default --user=default
kubectl config use-context default

## Docker for the upgrade_toolbelt tool ( legacy )

    host$ docker build -t upgrade_toolbelt .
    host$ docker run --rm --env 'UTB_OWNER_AND_REPO=benjaminoakes/maid' --env 'UTB_JOB_COUNT=11' -v "$PWD:/opt" -v "$HOME/var/ci":/var/ci -i -t upgrade_toolbelt sh -l
    container$ utb-build-analyze 407
