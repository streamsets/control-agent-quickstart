#!/bin/bash
echo Running login.sh

export KUBE_CREATE_CLUSTER=0
export KUBE_DELETE_CLUSTER=0

: ${KUBE_CONTEXT_NAME:=?}
export KUBE_CONTEXT_NAME

if [ -z "${KUBE_NAMESPACE}" ]; then
  echo "ERROR: Varaible KUBE_NAMESPACE has not been set. Must set to a namespace to be created or '?' to use the namespace from current kubectl context."
  exit 1
fi

source ../common/common-login.sh

echo Exiting login.sh
