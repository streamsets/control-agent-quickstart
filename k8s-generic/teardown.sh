#!/bin/bash
echo Running teardown.sh

source login.sh

${COMMON_DIR}/common-teardown-services.sh

${COMMON_DIR}/common-kubectl-cleanup.sh
