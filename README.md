# Mongo/Vault Secret Injection

*********************************

##Mongo

####Setup

1. From the project root, run `./scripts/mongod/setup.sh` to deploy the mongod statefulset.
2. Verify the pods are running `kubectl get po -n mongo-vault-secret-injection`
3. Add admin user to enable access to the cluster `./scripts/mongod/add-admin-user.sh`.

####Teardown
1. From the project root, run `./scripts/mongod/teardown.sh`

<br>

*********************************

##Vault

####Setup
1. TO-DO

####Teardown
1. TO-DO


<br>

*********************************
