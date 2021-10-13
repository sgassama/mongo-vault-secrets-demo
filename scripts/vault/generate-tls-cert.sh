#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
NS=mvsd-vault
# SERVICE is the name of the Vault service in Kubernetes.
# It does not have to match the actual running service, though it may help for consistency.
SERVICE=vault-agent-injector-svc
# SECRET_NAME to create in the Kubernetes secrets store.
SECRET_NAME=vault-server-tls
# cert signing request name
CSR_NAME=mvsd-vault-csr

# Create namespace
if grep -q -w $NS <<<"$(kubectl get ns)"; then
  echo "$NS namespace already exists. Skipping to next step."
else
  echo "creating namespace: $NS"
  kubectl create ns $NS
fi

# TMPDIR is a temporary working directory.
mkdir -p "$SCRIPT_DIR/certs"
TMPDIR="$SCRIPT_DIR/certs"
#TMPDIR=$(mktemp -d)
echo "TMPDIR: $TMPDIR"

# Create a key for Kubernetes to sign.
openssl genrsa -out "$TMPDIR/vault.key" 2048
cat "${TMPDIR}/vault.key"

# Create a file ${TMPDIR}/csr.conf with the following contents:
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

# Create a CSR
openssl req -new -key "${TMPDIR}/vault.key" -subj "/CN=${SERVICE}.${NS}.svc" -out "${TMPDIR}/server.csr" -config "${TMPDIR}/csr.conf"


# Create a k8s CSR resource config
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

# Create a k8s CSR resource config
if grep -q -w ${CSR_NAME} <<<"$(kubectl get CertificateSigningRequest)"; then
  kubectl delete CertificateSigningRequest ${CSR_NAME}
fi
kubectl create -f "${TMPDIR}/csr.yaml"

# Wait for CSR to be received and processed
sleep 5

# Approve the CSR in Kubernetes.
kubectl certificate approve ${CSR_NAME}

# Retrieve the certificate.
serverCert=$(kubectl get csr ${CSR_NAME} -o jsonpath='{.status.certificate}')

# Write the certificate out to a file.
echo "${serverCert}" | openssl base64 -d -A -out "${TMPDIR}/vault.crt"

# Retrieve Kubernetes CA.
kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 -d >"${TMPDIR}/vault.ca"

cat <<EOF | kubectl --namespace $NS apply -f -
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: vault-admin-binding
subjects:
- kind: Group
  # This value is the one that k8s uses to define group membership
  # Must be the same in the openssl subject
  name: vault-admin
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF

# Store the key, cert, and Kubernetes CA into Kubernetes secrets.
if grep -q -w ${SECRET_NAME} <<<"$(kubectl --namespace ${NS} get secret)"; then
  kubectl --namespace ${NS} delete secret ${SECRET_NAME}
fi
kubectl -n ${NS} create secret generic ${SECRET_NAME} \
  --namespace ${NS} \
  --from-file=tls.key="${TMPDIR}/vault.key" \
  --from-file=tls.crt="${TMPDIR}/vault.crt" \
  --from-file=vault-ca="${TMPDIR}/vault.ca"

kubectl get secret -n $NS

# Verify the certificate:
openssl x509 -in "${TMPDIR}/vault.crt" -noout -text

# Delete CSR and secret if exist
if grep -q -w ${CSR_NAME} <<<"$(kubectl get csr)"; then
  kubectl delete csr ${CSR_NAME} -n ${NS}
fi
