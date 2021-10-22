#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
NS=mvsd-mongod

# create namespace
if grep -q -w ${NS} <<<"$(kubectl get ns)"; then
  echo "${NS} namespace already exists. Skipping to next step."
else
  echo "creating namespace: ${NS}"
  kubectl create ns ${NS}
fi

# deploy mongo
kubectl -n ${NS} apply -f "${SCRIPT_DIR}/../../k8s/mongod/mongod.yaml"
sleep 10

#
printf '\nk8s get all -n %s\n' "${NS}"
kubectl get all -n ${NS}
printf '\nk8s get secret -n %s\n' "${NS}"
kubectl get secret -n ${NS}
printf '\nk8s get persistent volume claims -n %s\n' "${NS}"
kubectl get persistentvolumeclaims -n ${NS}
printf '\nk8s get persistent volumes\n'
kubectl get persistentvolumes
printf '\nRun the following command until all "mongod" pods are shown as running: "kubectl get po -w -n %s"\n' "${NS}"
