#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

NS=mvsd-demo-app
SECRET_NAME=dockercred

# create namespace
if grep -q -w ${NS} <<<"$(kubectl get ns)"; then
  echo "${NS} namespace already exists. Skipping to next step."
else
  echo "creating namespace: ${NS}"
  kubectl create ns ${NS}
fi

# create docker creds secret
if grep -q -w ${SECRET_NAME} <<<"$(kubectl get secret -n ${NS})"; then
  echo "${NS} secret already exists. Skipping to next step."
else
  echo "creating docker secret: ${SECRET_NAME}"
  kubectl -n ${NS} create secret generic ${SECRET_NAME} \
    --from-file=.dockerconfigjson="${HOME}/.docker/config.json" \
    --type=kubernetes.io/dockerconfigjson
fi
