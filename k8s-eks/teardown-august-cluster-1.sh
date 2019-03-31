#!/bin/bash 
source august-cluster-1-env.sh
export KUBE_DELETE_CLUSTER=1 
time ./teardown.sh
