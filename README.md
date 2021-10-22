# Mongo/Vault Secret Injection

*********************************
> NOTE: Two dependencies (`jq` and `yq`) will need to be installed on your machine in order to follow these instructions. 

## Mongo

#### Setup

1. From the project root, run:
```
./scripts/mongod/deploy-mongod.sh
``` 
This deploys a `mongod` statefulset with 3 replicas. Each pod contains a sidecar `cvallance/mongo-k8s-sidecar` which monitors the namespace for any `mongod` containers and adds them to a replicaset.
2. Verify the pods are running:
```
kubectl get po -n mvsd-mongod
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
This script cleans up the `mvsd-mongod` namespace. It also removes the persistent volumes associated to each statefulset member.

*********************************

## Vault

#### Setup
1. From the project root, run:
```
./scripts/vault/generate-tls-cert.sh
```
2. From the project root, run:
```
./scripts/vault/deploy-vault.sh
``` 
This deploys a `vault` server, a secret injector, along with the RBAC policies necessary to inject secrets from the vault agent.
3. Verify that the container has been deployed: 
```
kubectl -n mvsd-vault get po
```
The output should look similar to the following: 
```
NAME                                    READY   STATUS    RESTARTS   AGE
vault-0                                 0/1     Running   0          24s
vault-agent-injector-xxx-xxx            1/1     Running   0          23s
```
4. From the project root, run:
```
./scripts/vault/init-vault.sh
```
This script initializes the vault operator and stores the keys needed to unseal the vault in `./scripts/vault/vault-keys.txt`
5. From the project root, run: 
```
./scripts/vault/unseal-vault.sh
```
> NOTE: Vault is initially in a 'sealed' state and this script unseals it since that has to be done before secrets can be stored and/or retrieved.
> At this point the `vault-0` should be in a `running` state. 

6. Verify by running: 
```
kubectl -n mvsd-vault get po
``` 
The output should look similar to the following:
```
NAME                                    READY   STATUS    RESTARTS   AGE
vault-0                                 1/1     Running   0          9m46s
```
7. Verify that vault is ready for secret storage/management:
```
kubectl exec -n mvsd-vault -it pod/vault-0 -- vault status | grep -E -i 'initialized|sealed'
```
You should see an output of `Initialized     true` and `Sealed          false` 

---

#### Vault Authentication Config
1. Exec into the vault container
```
kubectl exec -it -n mvsd-vault vault-0 -- /bin/sh
```
2. Enable & configure the Kubernetes authentication method: 
```
vault auth enable kubernetes
```
2. Set vault token config:
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
1. Exec into the vault container
```
kubectl exec -it -n mvsd-vault vault-0 -- /bin/sh
```
2. Enable kv-v2 secrets at the path 
`internal`: 
```
vault secrets enable -path=internal kv-v2
```
2. Create secrets at the path `internal/database/config`: 
```
vault kv put internal/database/config DB_PASS=MyPa55wd123 DB_USER=main_admin
``` 
3. Verify that the secret has been stored:
```
vault kv get internal/database/config
```
4. Create a new policy named `read-internal-db-secret.hcl` that enables read capability for secrets at path `internal/data/database/config`: 
```
vault policy write read-internal-db-secret - <<EOF
path "internal/data/database/config" {
  capabilities = ["read"]
}
EOF
```
> NOTE: Notice that the policy path `(internal/data/database/config)` includes the `/data/`, however when reading/writing a secret the `/data/` portion is omitted. E.g. `vault kv put internal/database/config`.
4. Create a role to link to the previously-created policy `read-internal-db-secret.hcl`:
```
vault write auth/kubernetes/role/vault-read-internal-db-secret \
  bound_service_account_names=mvsd-demo-app \
  bound_service_account_namespaces=mvsd-demo-app \
  policies=read-internal-db-secret \
  ttl=1h
```
> Any pod within the `mvsd-demo-app` namespace attached to the `mvsd-demo-app` serviceAccount should now be able to read the secret created in step #2. Generated tokens will be valid for 1 hour.

___

#### Teardown
1. From the project root, run: 
```
./scripts/vault/teardown.sh
```

*********************************

## Demo App

> NOTE: ./k8s/demo-app/values.yaml or other variables 
> may have to be changed if you modify any of the steps below.  

#### Setup
1. Build and push the docker image:
```
 docker build -t siakag/mongo-vault-secrets-demo:1.0.0 . -f ./mongo-vault-secrets-demo.Dockerfile
```
```
 docker push siakag/mongo-vault-secrets-demo:1.0.0
```
2. Create a secret to enable obtaining your docker image
```
./scripts/demo-app/create-dockercred-secret.sh
```
3. Deploy demo-app initially without vault secret functionality:
```
./scripts/demo-app/deploy-demo-app.sh
```
3. The logs should show that demo-app errors out as a result of not having the secrets injected. Verify this by running:
```
POD=$(kubectl get po -n mvsd-demo-app | awk 'NR == 2' | awk '{print $1}')
```
and then:
```
kubectl logs -n mvsd-demo-app $POD
```
the output should include the following:
```
ERROR:
[Error: ENOENT: no such file or directory, open '/vault/secrets/config.json'] {
  errno: -2,
  code: 'ENOENT',
  syscall: 'open',
  path: '/vault/secrets/config.json'
}
```
4. Now we can patch the deployment to enable secrets in demo-app:
```
kubectl patch deployment.apps/mvsd-demo-app-deployment -n mvsd-demo-app --patch "$(cat ./k8s/demo-app/patch/demo-app-patch.yaml)"
```
5. Verify that the pod has accessed the vault secrets and has connected to the mongo database:
```
POD=$(k get po -n mvsd-demo-app | awk 'NR == 2' | awk '{print $1}')
```
and then:
```
kubectl logs -n mvsd-demo-app $POD
```
___
you should see a log stating that it has connected to the database successfully:
```
Database open! ...
```

#### Teardown
1. Run the teardown script from the project root: 
```
./scripts/demo-app/teardown.sh
```
