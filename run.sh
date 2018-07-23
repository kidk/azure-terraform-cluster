#!/usr/bin/env bash
set -e

#
# Cluster variables
#

# Number of linux nodes to prepare
CLUSTER_NODES_LINUX=2

# Number of windows nodes to prepare
CLUSTER_NODES_WINDOWS=1

# Resource group name and location
AZURE_RESOURCE_GROUP=test-cluster
AZURE_RESOURCE_LOCATION=westeurope

# Admin username and password
# For Linux your local ssh key is used and Windows will use password
ADMIN_USERNAME=$(whoami)
ADMIN_PASSWORD=NeedsToBe8CharsPlusNumberAndCapital

#
# Don't change anything below this line
#

# Init terraform
pushd terraform
terraform init

# Action
ACTION=${1:-apply}

# Run terraform
if [ "$ACTION" = "output" ]
then
    terraform $ACTION
else
    terraform $ACTION \
        -var "cluster_nodes_linux=$CLUSTER_NODES_LINUX" \
        -var "cluster_nodes_windows=$CLUSTER_NODES_WINDOWS" \
        -var "azure_resource_group=$AZURE_RESOURCE_GROUP" \
        -var "azure_resource_location=$AZURE_RESOURCE_LOCATION" \
        -var "admin_username=$ADMIN_USERNAME" \
        -var "admin_password=$ADMIN_PASSWORD"
fi

popd
