#!/bin/bash
source login.sh
echo startup-services.sh KUBE_NAMESPACE ${KUBE_NAMESPACE}
${COMMON_DIR}/common-startup-services.sh
