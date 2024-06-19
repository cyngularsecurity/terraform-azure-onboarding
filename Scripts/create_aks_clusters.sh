#!/bin/bash

# Usage: ./manage_aks.sh create|delete resource_group cluster_name region

if [[ $# -ne 4 ]]; then
    echo "Usage: $0 create|delete <resource_group> <cluster_name> <region>"
    exit 1
fi

ACTION=$1
RESOURCE_GROUP=$2
CLUSTER_NAME=$3
REGION=$4

create_cluster() {
    echo "Creating AKS cluster '$CLUSTER_NAME' in resource group '$RESOURCE_GROUP' and region '$REGION'..."
    
    az group create --name $RESOURCE_GROUP --location $REGION
    az aks create --resource-group $RESOURCE_GROUP -\
      -name $CLUSTER_NAME \
      --location $REGION \
      --node-count 1 \
      --enable-addons monitoring \
      --generate-ssh-keys

    echo "AKS cluster '$CLUSTER_NAME' created successfully."
}

delete_cluster() {
    echo "Deleting AKS cluster '$CLUSTER_NAME' in resource group '$RESOURCE_GROUP' and region '$REGION'..."
    
    # Delete the AKS cluster
    az aks delete --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --yes --no-wait

    # Optionally delete the resource group
    az group delete --name $RESOURCE_GROUP --yes --no-wait

    echo "AKS cluster '$CLUSTER_NAME' deleted successfully."
}

case $ACTION in
    create)
        create_cluster
        ;;
    delete)
        delete_cluster
        ;;
    *)
        echo "Invalid action specified. Use 'create' or 'delete'."
        exit 1
        ;;
esac