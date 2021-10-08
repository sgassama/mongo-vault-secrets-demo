#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
NS=vault-injector

#################################################################################
#################################################################################
#################################################################################
# create namespace
if grep -q -w $NS <<<"$(kubectl get ns)"; then
  echo "$NS namespace already exists. Skipping to next step."
else
  echo "creating namespace: $NS"
  kubectl create ns $NS
fi

#################################################################################
#################################################################################
#################################################################################
# deploy mongo
kubectl -n $NS apply -f "$SCRIPT_DIR/../../k8s/vault.yaml"
sleep 10

#################################################################################
#################################################################################
#################################################################################
# add admin user
printf '\nk8s get all -n %s\n' "$NS"
kubectl get all -n $NS
printf '\nRun the following to see all the "vault" pods: "kubectl get po -w -n %s"\n' "$NS"
