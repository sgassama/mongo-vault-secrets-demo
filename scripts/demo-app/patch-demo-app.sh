#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
NS=mvsd-demo-app

# patch demo-app
kubectl patch deployment.apps/${NS}-deployment -n ${NS} --patch "$(cat "${SCRIPT_DIR}/../../k8s/demo-app/patch/demo-app-patch.yaml")"
sleep 10

# add admin user
printf '\nk8s get all -n %s\n' "${NS}"
kubectl get all -n ${NS}
