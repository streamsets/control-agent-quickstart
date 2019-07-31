#!/bin/bash
source login.sh
echo startup-services-agent.sh KUBE_NAMESPACE ${KUBE_NAMESPACE}
exit

${COMMON_DIR}/common-startup-services-agent.sh $@
