#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
NS=mvsd-demo-app

# deploy demo-app
#kubectl -n ${NS} apply -f "${SCRIPT_DIR}/../../k8s/demo-app/demo-app.yaml"
helm upgrade --install ${NS} "${SCRIPT_DIR}/../../k8s/demo-app/" \
  --namespace ${NS}
sleep 10

# add admin user
printf '\nk8s get all -n %s\n' "${NS}"
kubectl get all -n ${NS}
