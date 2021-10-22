#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

NS=mvsd-demo-app
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Delete statefulsets, svcs, and secrets
helm delete -n ${NS} ${NS}
sleep 10

#
kubectl delete ns ${NS}
