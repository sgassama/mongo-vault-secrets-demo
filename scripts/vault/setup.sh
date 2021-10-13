#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
NS=mvsd-vault
SECRET_NAME=vault-server-tls

#################################################################################
#################################################################################
#################################################################################
CA_BUNDLE=$(kubectl get secrets/${SECRET_NAME} --namespace ${NS} -o jsonpath="{.data.vault-ca}")
#echo "CA_BUNDLE: $CA_BUNDLE"

# deploy vault
helm upgrade --install --namespace ${NS} vault hashicorp/vault \
    --set="injector.certs.secretName=${SECRET_NAME}" \
    --set="listener.tcp.tls_disable=false" \
    --set="injector.certs.caBundle=${CA_BUNDLE}" >"$SCRIPT_DIR/output.yaml"
#helm upgrade --install --namespace ${NS} vault hashicorp/vault --version=0.16.1 \
#    --set='server.image.repository=vault' \
#    --set='server.image.tag=123.456' \
#    --output yaml \
#    --dry-run >"$SCRIPT_DIR/output.yaml"
#kubectl -n $NS apply -f "$SCRIPT_DIR/../../k8s/vault/vault.yaml"
#sleep 20

#################################################################################
#################################################################################
#################################################################################
# add admin user
printf '\nk8s get all -n %s\n' "$NS"
kubectl get all -n $NS
printf '\nRun the following to see all the "vault" pods: "kubectl get po -w -n %s"\n' "$NS"

kubectl get po -w -n $NS

sleep 10
exit 0
