#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

NS=mongo-vault-secret-injection

#################################################################################
#################################################################################
#################################################################################
# provision replica set
echo 'Configuring the MongoDB Replica Set'
SERVICE_DOMAIN="mongodb-service.$NS.svc.cluster.local"
SERVICE_PORT=27017

kubectl -n $NS exec mongod-0 -- mongo --eval \
  "rs.initiate({_id: 'MainRepSet', version: 1, members: [ {_id: 0, host: 'mongod-0.$SERVICE_DOMAIN:$SERVICE_PORT'}, {_id: 1, host: 'mongod-1.$SERVICE_DOMAIN:$SERVICE_PORT'}, {_id: 2, host: 'mongod-2.$SERVICE_DOMAIN:$SERVICE_PORT'} ]});"

echo "Waiting for the Replica Set to initialise..."
sleep 30
kubectl -n $NS exec mongod-0 -- mongo --eval 'rs.status();'
