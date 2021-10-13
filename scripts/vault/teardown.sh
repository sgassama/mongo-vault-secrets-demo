#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

NS=mvsd-vault

#################################################################################
#################################################################################
#################################################################################
# Delete the associated resources
helm uninstall vault -n ${NS}
sleep 3

kubectl delete ns $NS
