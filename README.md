# control-agent-quickstart

This project provides pre-built scripts to configure Streamsets Control Hub (SCH) to work with various Kubernetes (K8s) providers.  You may use an existing K8s cluster or have the scripts generate a new one.

These configurations are for demonstration purposes only and will require modification for use in a production environment.


## Prerequisites:

1. kubectl
2. jq

*See the individual K8s Provider folders for additional prerequisites.*


## Usage

*See the individual K8s Provider folders for startup and teardown examples.*


## Environment Variables
The following properties are common to all versions of this script.  

*See the individual K8s Provider folders for additional environment variable information.*


### Required

SCH_ORG - SCH Org you wish to connect to K8s.

SCH_USER - SCH User Id within Org with admin rights.  Format should be <user>@<org>

SCH_PASSWORD - SCH Password


### Optional

SCH_URL - URL of SCH instance.  Default is "https://cloud.streamsets.com"

KUBE_NAMESPACE - namespace to be created/used in K8s.  Default "streamsets"
