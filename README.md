# Mongo/Vault Secret Injection

*********************************

## Mongo

#### Setup

1. From the project root, run:
```
./scripts/mongod/setup.sh
``` 
This deploys a `mongod` statefulset with 3 replicas. Each pod contains a sidecar `cvallance/mongo-k8s-sidecar` which monitors the namespace for any `mongod` containers and adds them to a replicaset.
2. Verify the pods are running:
```
kubectl get po -n mongo-vault-secret-injection
```
You should see an output similar to this: 
```
NAME                   READY   STATUS    RESTARTS   AGE
mongod-statefulset-0   2/2     Running   0          3s
mongod-statefulset-1   2/2     Running   0          3s
...
mongod-statefulset-n   2/2     Running   0          3s
```
3. Add admin user to enable access to the cluster:
```
./scripts/mongod/add-admin-user.sh
```
This creates an admin user `admin_user` with the password provided to the script.

> Usage: `./scripts/mongod/add-admin-user.sh myPassword123`
---

#### Teardown
1. From the project root, run:
```
./scripts/mongod/teardown.sh
```
This script cleans up the `mongo-vault-secret-injection` namespace. It also removes the persistent volumes associated to each statefulset member.

*********************************

## Vault

#### Setup
1. From the project root, run:
```
./scripts/vault/setup.sh
``` 
This deploys a `vault` server, a secret injector, along with the RBAC policies necessary to inject secrets from the vault agent.
2. Verify that the container has been deployed: 
```
kubectl -n vault-injector get po
```
The output should look similar to the following: 
```
NAME                                    READY   STATUS    RESTARTS   AGE
vault-0                                 0/1     Running   0          24s
vault-agent-injector-xxx-xxx            1/1     Running   0          23s
```
3. From the project root, run:
```
./scripts/vault/init-vault.sh
```
This script initializes the vault operator and stores the keys needed to unseal the vault in `./scripts/vault/vault-keys.json`
4. From the project root, run: 
```
./scripts/vault/unseal-vault.sh
```
> NOTE: Vault is initially in a 'sealed' state and this script unseals it since that has to be done before secrets can be stored and/or retrieved.
> At this point the `vault-0` should be in a `running` state. 

5. Verify by running: 
```
kubectl -n vault-injector get po
``` 
The output should look similar to the following:
```
NAME                                    READY   STATUS    RESTARTS   AGE
vault-0                                 1/1     Running   0          9m46s
```
6. Verify that vault is ready for secret storage/management:
```
kubectl exec -n vault-injector -it pod/vault-0 -- vault status | grep -E -i 'initialized|sealed'
```
You should see an output of `Initialized     true` and `Sealed          false` 

---

#### Vault Authentication Config
1. Exec into the vault container: 
```
kubectl exec -n vault-injector -it pod/vault-0 -- /bin/sh
```
2. Enable & configure the Kubernetes authentication method: 
```
vault auth enable kubernetes
```
3. Set vault token config:
```
vault write auth/kubernetes/config \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  issuer="https://kubernetes.default.svc.cluster.local"
```
>  NOTE: Your cluster issuer can be verified by running the following and looking at the `.well-known/openid-configuration`:
> ```
> kubectl proxy & \
> curl --silent http://127.0.0.1:8001/.well-known/openid-configuration | jq -r .issuer
> ```

---

#### Vault Secrets
1. Enable kv-v2 secrets at the path 
`internal`: 
```
vault secrets enable -path=internal kv-v2
```
2. Create a secret at the path `internal/database/config`: 
```
vault kv put internal/database/config TOKEN=slidingYouOnSight
```
3. Create a new policy named `read-internal-db-secret.hcl` that enables read capability for secrets at path `internal/data/database/config`: 
```
vault policy write read-internal-db-secret.hcl - <<EOF
path "internal/data/database/config" {
  capabilities = ["read"]
}
EOF
```
> NOTE: Notice that the policy path `(internal/data/database/config)` includes the `/data/`, whereas when reading/writing a secret the `/data/` portion is omitted. E.g. `vault kv put internal/database/config`.
4. Create a role to link to the previously-created policy `read-internal-db-secret.hcl`:
```
vault write auth/kubernetes/role/vault-read-internal-db-secret \
  bound_service_account_names=mongo-vault-secrets-demo \
  bound_service_account_namespaces=mongo-vault-secrets-demo \
  policies=read-internal-db-secret.hcl \
  ttl=1h
```
> Any pod within the `mongo-vault-secrets-demo` namespace attached to the `mongo-vault-secrets-demo` should now be able to read the secret created in step #2. Generated tokens will be valid for 1 hour.

___

#### Teardown
1. From the project root, run: 
```
./scripts/vault/teardown.sh
```

*********************************
