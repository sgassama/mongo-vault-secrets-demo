#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
NS=mongo-vault-secret-injection
SECRET_NAME=shared-bootstrap-data

#################################################################################
#################################################################################
#################################################################################
# create namespace
if grep -q $NS <<<"$(kubectl get ns)"; then
  echo "$NS namespace already exists. Skipping to next step."
else
  echo "creating namespace: $NS"
  kubectl create ns $NS
fi

# create shared namespace secret
if grep -q $SECRET_NAME <<<"$(kubectl -n $NS get secret)"; then
  echo "$SECRET_NAME secret already exists. Skipping to next step."
else
  echo "creating secret: $SECRET_NAME"
  TMP_FILE=$(mktemp)
  openssl rand -base64 741 >"$TMP_FILE"
  kubectl -n $NS create secret generic $SECRET_NAME --from-file=internal-auth-mongodb-keyfile="$TMP_FILE"
  rm "$TMP_FILE"
fi

#################################################################################
#################################################################################
#################################################################################
# deploy mongo
kubectl -n $NS apply -f "$SCRIPT_DIR/../../k8s/mongod.yaml"
sleep 10

#################################################################################
#################################################################################
#################################################################################
# add admin user
printf '\nk8s get all -n %s\n' "$NS"
kubectl get all -n $NS
printf '\nk8s get secret -n %s\n' "$NS"
kubectl get secret -n $NS
printf '\nk8s get persistent volumes -n %s\n' "$NS"
kubectl get persistentvolumes -n $NS
printf '\nRun the following command until all "mongod" pods are shown as running: "kubectl get statefulsets -w -n %s"\n' "$NS"
