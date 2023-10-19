package main

import (
	"context"
	"fmt"
	"log"

	"github.com/Azure/azure-sdk-for-go/profiles/latest/network/mgmt/network"
	"github.com/Azure/azure-sdk-for-go/profiles/latest/resources/mgmt/resources"
	"github.com/Azure/go-autorest/autorest/azure/auth"
)

func main() {
	// Create a new Azure session with a device login
	authorizer, err := auth.NewAuthorizerFromEnvironment()
	if err != nil {
		log.Fatalf("Failed to get Azure authorizer: %v", err)
	}

	subscriptionsClient := resources.NewSubscriptionsClient()
	subscriptionsClient.Authorizer = authorizer

	// List all subscriptions for the current tenant
	subscriptionListResult, err := subscriptionsClient.List(context.Background())
	if err != nil {
		log.Fatalf("Failed to list subscriptions: %v", err)
	}

	for _, subscription := range subscriptionListResult.Values() {
		// For each subscription, list all resource groups
		resourceGroupsClient := resources.NewGroupsClient(*subscription.SubscriptionID)
		resourceGroupsClient.Authorizer = authorizer

		rgListResult, err := resourceGroupsClient.List(context.Background(), "", nil)
		if err != nil {
			log.Fatalf("Failed to list resource groups for subscription %s: %v", *subscription.SubscriptionID, err)
		}

		for _, rg := range rgListResult.Values() {
			// For each resource group, list all network interfaces
			nicClient := network.NewInterfacesClient(*subscription.SubscriptionID)
			nicClient.Authorizer = authorizer

			nicListResult, err := nicClient.ListComplete(context.Background(), *rg.Name)
			if err != nil {
				log.Fatalf("Failed to list network interfaces for resource group %s: %v", *rg.Name, err)
			}

			for nicListResult.NotDone() {
				nic := nicListResult.Value()

				// Configure Network Watcher for each network interface here
				// TODO: Add logic to configure network watcher for the NIC

				fmt.Printf("Processed network interface: %s\n", *nic.Name)

				err = nicListResult.NextWithContext(context.Background())
				if err != nil {
					log.Fatalf("Failed to get next network interface: %v", err)
				}
			}
		}
	}
}
