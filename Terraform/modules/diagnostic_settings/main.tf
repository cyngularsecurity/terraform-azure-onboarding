locals {
  # resource_names = {
  #   for r_id in var.sub_resources_ids :
  #   # Extract the resource name from resource ID | format: /subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/<resource-type>/<resource-name>
  #   split("/", r_id)[length(split("/", r_id)) - 1] => r_id
  # }
  sub_resource_ids = flatten([
    for rg in var.sub_resource_group_names : [
      for id in try(values(data.external.resource_ids[rg].result), []) : id
    ]
  ])
  sub_resource_locations = flatten([
    for rg in var.sub_resource_group_names : [
      for l in try(values(data.external.resource_locations[rg].result), []) : l
    ]
  ])
  categorize = { # Function to categorize resource types based on resource ID using regex
    for id in local.sub_resource_ids : id => (
      length(regexall("Microsoft.Compute/components", id)) > 0 ? { type = "category_group", value = "allLogs" } :
      length(regexall("Microsoft.Compute/bastionHosts", id)) > 0 ? { type = "category_group", value = "allLogs" } :

      length(regexall("Microsoft.KeyVault/vaults", id)) > 0 ? { type = "category_group", value = "allLogs,audit" } :
      length(regexall("Microsoft.Sql/servers", id)) > 0 ? { type = "category_group", value = "allLogs,audit" } :
      length(regexall("Microsoft.OperationalInsights/workspaces", id)) > 0 ? { type = "category_group", value = "allLogs,audit" } :
      length(regexall("Microsoft.Network/publicIPAddresses", id)) > 0 ? { type = "category_group", value = "allLogs,audit" } :
      length(regexall("Microsoft.EventHub/namespaces", id)) > 0 ? { type = "category_group", value = "allLogs,audit" } :
      length(regexall("Microsoft.DBforMySQL/flexibleServers", id)) > 0 ? { type = "category_group", value = "allLogs,audit" } :
      { type = "category", value = "AuditEvent" }
    )
  }

  excluded_types = join(",", [ // resource types to not configure diagnostic settings for
    "Microsoft.Storage/storageAccounts",

    "Microsoft.Network/virtualNetworks",
    "Microsoft.Network/networkWatchers",
    # "microsoft.network/networkwatchers/flowlogs", //*
    "Microsoft.Network/networkInterfaces",
    "microsoft.network/routetables",           //*
    "microsoft.network/privateendpoints",      //*
    "Microsoft.Network/loadBalancers",         //* LoadBalancerHealthEvent */
    "Microsoft.Network/networkManagers",       //**/
    "Microsoft.Network/networkSecurityGroups", //* NetworkSecurityGroupEvent | NetworkSecurityGroupRuleCounter */
    # "Microsoft.Network/publicIPAddresses", //**/

    "Microsoft.Web/serverFarms",
    "Microsoft.Web/sites",

    "Microsoft.Compute/disks",
    "Microsoft.Compute/snapshots",
    "Microsoft.Compute/sshPublicKeys",
    "Microsoft.Compute/virtualMachines",
    "microsoft.compute/availabilitysets",           //*
    "microsoft.compute/virtualmachines/extensions", //*
    "Microsoft.Compute/virtualMachineScaleSets",    //**/

    "microsoft.operationsmanagement/solutions",         //*
    "microsoft.managedidentity/userassignedidentities", //*
    "microsoft.devtestlab/labs",                        //*
    # "microsoft.devtestlab/labs/virtualmachines", //**/
    "microsoft.databricks/accessconnectors",    //*
    "Microsoft.Databricks/workspaces",          //**/
    "microsoft.operationalinsights/querypacks", //*

    "Microsoft.EventGrid/systemTopics", //* DeliveryFailures */

    "microsoft.insights/components",              //**/
    "Microsoft.ContainerService/managedClusters", //**/

    "Microsoft.RecoveryServices/vaults", //**/
    "Microsoft.KeyVault/vaults",         //**/

    "Microsoft.Sql/servers", //**/

    "Microsoft.ClassicNetwork/networkSecurityGroups", //**/

    "Microsoft.ServiceBus/namespaces",           //**/
    "Microsoft.DBforPostgreSQL/flexibleServers", //**/
    "microsoft.compute/images",                  //* N/A */

    "microsoft.devtestlab/schedules", //**/
  ])
}