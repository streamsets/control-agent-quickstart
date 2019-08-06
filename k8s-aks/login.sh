#!/bin/bash
echo Running login.sh

export PROVIDER_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export COMMON_DIR=`echo $(cd ${PROVIDER_DIR}/../common; pwd)`

if [ -z "$(which az)" ]; then
  echo "This script requires the 'az cli' utility"
  echo "Please install it via one of the methods described here:"
  echo "https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest"
  exit 1
fi

source ${COMMON_DIR}/common-login.sh
echo login.sh KUBE_NAMESPACE ${KUBE_NAMESPACE}

echo Exiting login.sh
