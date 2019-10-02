#!/bin/bash
echo Running startup-services.sh

source login.sh
${COMMON_DIR}/common-startup-services.sh

echo Exiting startup-services.sh
