# Mongo/Vault Secret Injection

*********************************

## Mongo

#### Setup

1. From the project root, run `./scripts/mongod/setup.sh` to deploy the mongod container.
> This deploys a `mongod` statefulset with 3 replicas. Each pod contains a sidecar `cvallance/mongo-k8s-sidecar` which monitors the namespace for any mongod containers and adds them to a replicaset.
2. Verify the pods are running `kubectl get po -n mongo-vault-secret-injection`
> You should see an output similar to this: 
> ```
> NAME                   READY   STATUS    RESTARTS   AGE
> mongod-statefulset-0   2/2     Running   0          3s
> mongod-statefulset-1   2/2     Running   0          3s
> ...
> mongod-statefulset-n   2/2     Running   0          3s
> ```
3. Add admin user to enable access to the cluster `./scripts/mongod/add-admin-user.sh`.
> This creates an admin user `admin_user` with the password provided to the script.
> 
> Usage: `./scripts/mongod/add-admin-user.sh myPassword123`

#### Teardown
1. From the project root, run `./scripts/mongod/teardown.sh`.
> This script cleans up the `mongo-vault-secret-injection` namespace. It also removes the persistent volumes associated to each statefulset member.

*********************************

## Vault

#### Setup
1. From the project root, run `./scripts/vault/setup.sh` to deploy the vault container.
> This deploys a `vault` server, a secret injector, along with the RBAC policies necessary to inject secrets from the vault agent.
2. From the project root, run /scripts/vault/init-vault.sh` to initialize the vault operator.
3. From the project root, run /scripts/vault/unseal-vault.sh`.

#### Teardown
1. From the project root, run `./scripts/vault/teardown.sh`.

*********************************
