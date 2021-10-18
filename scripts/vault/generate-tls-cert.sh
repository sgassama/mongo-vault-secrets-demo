#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

NS=mvsd-vault
SERVICE=vault-agent-injector-svc
TLS_SECRET_NAME=vault-server-tls
CSR_NAME=mvsd-vault-csr # cert signing request name
TMPDIR=$(mktemp -d)

#
if grep -q -w $NS <<<"$(kubectl get ns)"; then
  echo "$NS namespace already exists. Skipping to next step."
else
  echo "creating namespace: $NS"
  kubectl create ns $NS
fi

# create private key
openssl genrsa -out "$TMPDIR/vault.key" 2048

# create a CSR config file ${TMPDIR}/csr.conf
cat <<EOF >"${TMPDIR}/csr.conf"
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${SERVICE}
DNS.2 = ${SERVICE}.${NS}
DNS.3 = ${SERVICE}.${NS}.svc
DNS.4 = ${SERVICE}.${NS}.svc.cluster.local
IP.1 = 127.0.0.1
EOF

# create the CSR
openssl req -new -key "${TMPDIR}/vault.key" -subj "/CN=${SERVICE}.${NS}.svc" -out "${TMPDIR}/server.csr" -config "${TMPDIR}/csr.conf"

# generate k8s CSR resource config file
cat <<EOF >"${TMPDIR}/csr.yaml"
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: ${CSR_NAME}
spec:
  groups:
  - system:authenticated
  request: $(cat "${TMPDIR}/server.csr" | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

# create a k8s CSR resource from ${TMPDIR}/csr.yaml
if grep -q -w ${CSR_NAME} <<<"$(kubectl get CertificateSigningRequest)"; then
  kubectl delete CertificateSigningRequest ${CSR_NAME}
fi
kubectl create -f "${TMPDIR}/csr.yaml"

# approve the CSR
kubectl certificate approve ${CSR_NAME}

# retrieve the certificate
serverCert=$(kubectl get csr ${CSR_NAME} -o jsonpath='{.status.certificate}')

# write the certificate out to a file
echo "${serverCert}" | openssl base64 -d -A -out "${TMPDIR}/vault.crt"

# retrieve k8s CA
kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 -d >"${TMPDIR}/vault.ca"

# store the key, cert, and k8s CA in a secret
if grep -q -w ${TLS_SECRET_NAME} <<<"$(kubectl --namespace ${NS} get secret)"; then
  kubectl --namespace ${NS} delete secret ${TLS_SECRET_NAME}
fi
kubectl -n ${NS} create secret generic ${TLS_SECRET_NAME} \
  --namespace ${NS} \
  --from-file=tls.key="${TMPDIR}/vault.key" \
  --from-file=tls.crt="${TMPDIR}/vault.crt" \
  --from-file=vault-ca="${TMPDIR}/vault.ca"
#
kubectl get secret -n $NS | grep ${TLS_SECRET_NAME}
# verify the certificate:
openssl x509 -in "${TMPDIR}/vault.crt" -noout -text

# delete CSR and secret if exist
if grep -q -w ${CSR_NAME} <<<"$(kubectl get csr)"; then
  kubectl delete csr ${CSR_NAME}
fi
