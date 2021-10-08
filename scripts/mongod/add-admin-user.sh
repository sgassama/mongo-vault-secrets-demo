#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

NS=mongo-vault-secret-injection

# usage
usage() {
  echo 'You must provide one argument for the password of the "main_admin" user to be created'
  echo 'Usage: add-admin-user.sh MyPa55wd123'
  echo
  exit 1
}

#################################################################################
#################################################################################
#################################################################################
# Check for password argument
if [[ $# -eq 0 ]]; then
  usage
fi

#################################################################################
#################################################################################
#################################################################################
# add admin user
echo "Creating user: 'main_admin'"
kubectl -n $NS exec mongod-statefulset-0 -- mongo --eval \
  'db.getSiblingDB("admin").createUser({user:"main_admin",pwd:"'"${1}"'",roles:[{role:"root",db:"admin"}]});'
