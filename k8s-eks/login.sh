#!/bin/bash
#----------------------------------------------------------
# Contain variable and checks that are common to all SCH/K8S environemnt setups
#
# NOTE:  This script is currently only used by the EKS setup.  In the future it will be converted into a shared script uses by all SCH/K8s setups.
#----------------------------------------------------------

if [ -z "$(which aws)" ]; then
  echo "This script requires the 'az cli' utility"
  echo "Please install it via one of the methods described here:"
  echo "https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest"
  exit 1
fi

source ${COMMON_DIR}/common-login.sh
