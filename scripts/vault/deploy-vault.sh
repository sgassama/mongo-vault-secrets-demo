#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

#
NS=mvsd-vault
SECRET_NAME=vault-server-tls

#
CA_BUNDLE=$(kubectl get secrets/${SECRET_NAME} --namespace ${NS} -o jsonpath="{.data.vault-ca}")

# deploy vault chart
helm upgrade --install --namespace ${NS} vault hashicorp/vault \
  --set="injector.certs.secretName=${SECRET_NAME}" \
  --set="injector.certs.caBundle=${CA_BUNDLE}"

#
printf '\nk8s get all -n %s\n' "$NS"
kubectl get all -n $NS
printf '\nRun the following to see all the "vault" pods: "kubectl get po -w -n %s"\n' "$NS"
