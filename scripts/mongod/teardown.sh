#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

NS=mvsd-mongod
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Delete statefulsets, svcs, and secrets
kubectl -n ${NS} delete -f "${SCRIPT_DIR}/../../k8s/mongod/mongod.yaml"
sleep 10

# Delete persistent volume claims
kubectl delete persistentvolumeclaims -l role=mongo
#
kubectl delete ns ${NS}
