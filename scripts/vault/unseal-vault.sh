#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

NS=mvsd-vault
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

#
echo "Unsealing vault..."
kubectl -n $NS exec pod/vault-0 -- vault operator unseal "$(< "$SCRIPT_DIR/vault-keys.txt"  tr -d '"' | awk 'NR == 1' | awk '{print $4}')"
kubectl -n $NS exec pod/vault-0 -- vault operator unseal "$(< "$SCRIPT_DIR/vault-keys.txt"  tr -d '"' | awk 'NR == 2' | awk '{print $4}')"
kubectl -n $NS exec pod/vault-0 -- vault operator unseal "$(< "$SCRIPT_DIR/vault-keys.txt"  tr -d '"' | awk 'NR == 3' | awk '{print $4}')"

#
echo "Logging in to vault..."
cat "$SCRIPT_DIR/vault-keys.txt" | tr -d '"' | awk 'NR == 7' | awk '{print $4}'

kubectl -n $NS exec pod/vault-0 -- vault login "$(< "$SCRIPT_DIR/vault-keys.txt"  tr -d '"' | awk 'NR == 7' | awk '{print $4}')" \
  -method=cert \
  -tls-skip-verify=true \
  -ca-cert="/etc/tls/vault.ca" \
  -client-cert="/etc/tls/vault.crt" \
  -client-key="/etc/tls/vault.key" > "$SCRIPT_DIR/login-details.txt"
