#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

NS=mvsd-demo-app
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Delete statefulsets, svcs, and secrets
kubectl -n ${NS} delete -f "${SCRIPT_DIR}/../../k8s/demo-app/demo-app.yaml"
sleep 10

#
kubectl delete ns ${NS}
