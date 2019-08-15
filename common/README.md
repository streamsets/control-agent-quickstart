


## Action Scripts

#### common-login.sh

  - Contain variable and checks that are common to all SCH/K8S environemnt setups   


#### common-startup-services.sh <suffix>
  - Uses an existing EKS cluster and worker nodes.  Starts SCH Provisioning agent and SCH Deployment.  

  The name of the existing cluster is defined by the environment variable ${KUBE_CLUSTER_NAME} (see below for more details).

  The <suffix> parameter defines a unique string to be appended to the end of the agent name.


   > Note: The agent that is by deafule created with the original cluster using the startup.sh scipt is "01"


#### common-teardown-services.sh <suffix>
  - Deletes an SCH Provisioning agent and any dependent SCDeployments.  

  The name of the existing cluster is defined by thenvironment variable ${KUBE_CLUSTER_NAME} (see below fomore details).

  The <suffix> parameter defines a unique string to bappended to the end of the agent name.


  > Note: The agent that is created by default with the original clusteusing the startup.sh scipt is "01"
