locals {
  main_location = element(var.client_locations, 0)

  # policy_def_json  = jsondecode(data.local_file.policy_definition.content)
  # policy_json_path = "${path.module}/policy_def.json"

  resource_types = {
    list_a = join(",", [ // resource types to configure diagnostic settings for, with category group of allLogs
      "Microsoft.Compute/components",
      "Microsoft.Compute/bastionHosts",
    ])
    
    list_b = join(",", [ // resource types to configure diagnostic settings for, with category groups of allLogs, audit
      "Microsoft.KeyVault/vaults",
      "Microsoft.Sql/servers",
      "Microsoft.OperationalInsights/workspaces",
      "Microsoft.Network/publicIPAddresses",
      "Microsoft.EventHub/namespaces",
      "Microsoft.DBforMySQL/flexibleServers",
    ])

    black_listed = join(",", [ // resource types to not configure diagnostic settings for
      "Microsoft.Storage/storageAccounts",

      "Microsoft.Network/virtualNetworks",
      "Microsoft.Network/networkWatchers",
      "Microsoft.Network/networkInterfaces",
      "microsoft.network/routetables",
      "microsoft.network/privateendpoints",
      "Microsoft.Network/loadBalancers",
      "Microsoft.Network/networkManagers",
      "Microsoft.Network/networkSecurityGroups",

      "Microsoft.Web/serverFarms",
      "Microsoft.Web/sites",

      "Microsoft.Compute/disks",
      "Microsoft.Compute/snapshots",
      "Microsoft.Compute/sshPublicKeys",
      "Microsoft.Compute/virtualMachines",
      "microsoft.compute/availabilitysets",
      "microsoft.compute/virtualmachines/extensions",
      "Microsoft.Compute/virtualMachineScaleSets",

      "microsoft.operationsmanagement/solutions",
      "microsoft.managedidentity/userassignedidentities",
      "microsoft.devtestlab/labs",
      "microsoft.databricks/accessconnectors",
      "Microsoft.Databricks/workspaces",
      "microsoft.operationalinsights/querypacks",

      "Microsoft.EventGrid/systemTopics",

      "microsoft.insights/components",
      "Microsoft.ContainerService/managedClusters",

      "Microsoft.RecoveryServices/vaults",
      "Microsoft.KeyVault/vaults",

      "Microsoft.Sql/servers",

      "Microsoft.ClassicNetwork/networkSecurityGroups",

      "Microsoft.ServiceBus/namespaces",
      "Microsoft.DBforPostgreSQL/flexibleServers",
      "microsoft.compute/images",

      "microsoft.devtestlab/schedules",
    ])
  }
}