
locals {
  func_name = "cyngular-app-${var.client_name}"
  main_location   = element(var.client_locations, 0)
  # main_sub_id   = element(var.subscription_ids, 0)
  func_zip_url = "https://westus2sitesadev.blob.core.windows.net/cyngular-ob/cyngular_func.zip?se=2026-08-05T17%3A29Z&sp=r&spr=https&sv=2022-11-02&sr=b&sig=Wjvfpw9OxxdJ9x2Hjob6e3iYzdEl6chZ%2BrfMj7xQz0w%3D"

  mgmt_group_id   = data.azuread_client_config.current.tenant_id
  logging_enabled = var.enable_aks_logs || var.enable_flow_logs || var.enable_activity_logs || var.enable_audit_events_logs

  resource_types = {
    list_a = [ // resource types to configure diagnostic settings for, with category group of allLogs -- 1
      "Microsoft.Compute/components",
      "Microsoft.Compute/bastionHosts",
      "microsoft.recoveryservices/vaults",
      "Microsoft.Network/virtualNetworks",
      "microsoft.desktopvirtualization/workspaces",
      "microsoft.insights/datacollectionrules",
    ]

    list_b = [ // resource types to configure diagnostic settings for, with category groups of allLogs, audit -- 2
      "Microsoft.KeyVault/vaults",
      "Microsoft.OperationalInsights/workspaces",
      "Microsoft.Network/publicIPAddresses",
      "Microsoft.EventHub/namespaces",
      "Microsoft.DBforMySQL/flexibleServers",
      "microsoft.cache/redis",
      "Microsoft.ServiceBus/namespaces",
      "Microsoft.DBforPostgreSQL/flexibleServers",
      "microsoft.synapse/workspaces",
    ]

    # black_listed = join(",", [ // resource types to not configure diagnostic settings for )
    black_listed = [ // resource types to not configure diagnostic settings for
      "Microsoft.Storage/storageAccounts",

      "Microsoft.Network/networkWatchers",
      "Microsoft.Network/networkInterfaces",
      "Microsoft.Network/routetables",
      "Microsoft.Network/privateendpoints",
      "Microsoft.Network/loadBalancers",
      "Microsoft.Network/networkManagers",

      "Microsoft.Web/serverFarms",
      "Microsoft.Web/sites",

      "Microsoft.Compute/images",
      "Microsoft.Compute/disks",
      "Microsoft.Compute/snapshots",
      "Microsoft.Compute/sshPublicKeys",
      "Microsoft.Compute/virtualMachines",
      "Microsoft.Compute/availabilitysets",
      "Microsoft.Compute/virtualmachines/extensions",
      "Microsoft.Compute/virtualMachineScaleSets",

      "microsoft.operationsmanagement/solutions",
      "microsoft.managedidentity/userassignedidentities",

      "microsoft.devtestlab/labs",
      "microsoft.devtestlab/schedules",

      "Microsoft.Databricks/accessconnectors",
      "Microsoft.Databricks/workspaces",
      "microsoft.operationalinsights/querypacks",

      "Microsoft.EventGrid/systemTopics",

      "microsoft.insights/components",
      "Microsoft.ContainerService/managedClusters",

      "Microsoft.ClassicNetwork/networkSecurityGroups",

      "Microsoft.Sql/servers",
      "Microsoft.Sql/servers/databases",
      "Microsoft.Network/networkSecurityGroups",
      "microsoft.virtualmachineimages/imagetemplates",
      "microsoft.network/networkwatchers/flowlogs",
      "microsoft.compute/galleries/images/versions",
      "microsoft.compute/galleries",
      "microsoft.compute/galleries/images"
    ]
  }
}