#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

NS=vault-injector
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

#################################################################################
#################################################################################
#################################################################################
# Delete the associated resources
kubectl -n $NS delete -f "$SCRIPT_DIR/../../k8s/vault.yaml"
sleep 10

kubectl delete ns $NS
