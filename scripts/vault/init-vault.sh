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
# add admin user
echo "Initializing vault and saving seal keys..."
kubectl -n $NS exec pod/vault-0 -- vault operator init -format=json > "$SCRIPT_DIR/vault-keys.json"
