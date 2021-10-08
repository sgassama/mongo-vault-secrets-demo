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
echo "Unsealing vault..."
VAULT_UNSEAL_KEYS=$(jq ".unseal_keys_b64[]" "$SCRIPT_DIR/vault-keys.json")
kubectl -n $NS exec pod/vault-0 -- vault operator unseal "$(echo "$VAULT_UNSEAL_KEYS" |  tr -d '"' | awk 'NR == 1')"
kubectl -n $NS exec pod/vault-0 -- vault operator unseal "$(echo "$VAULT_UNSEAL_KEYS" |  tr -d '"' | awk 'NR == 2')"
kubectl -n $NS exec pod/vault-0 -- vault operator unseal "$(echo "$VAULT_UNSEAL_KEYS" |  tr -d '"' | awk 'NR == 3')"
