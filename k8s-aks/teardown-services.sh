#!/bin/bash
echo Running teardown-services.sh

source login.sh
${COMMON_DIR}/common-teardown-services.sh

echo Exiting teardown-services.sh
