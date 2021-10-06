#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

NS=mongo-vault-secret-injection
#################################################################################
#################################################################################
#################################################################################
# Delete statefulsets, svcs, and secrets
kubectl -n $NS delete statefulsets mongod-statefulset
kubectl -n $NS delete services mongodb-service
kubectl -n $NS delete secret shared-bootstrap-data
sleep 10

# Delete persistent volume claims
kubectl -n $NS delete persistentvolumeclaims -l role=mongo
kubectl delete ns $NS
