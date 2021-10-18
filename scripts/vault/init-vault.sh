#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

NS=mvsd-vault
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

echo "Initializing vault and saving seal keys..."
kubectl -n $NS exec pod/vault-0 -- vault operator init \
 -tls-skip-verify  >>"$SCRIPT_DIR/vault-keys.txt"
