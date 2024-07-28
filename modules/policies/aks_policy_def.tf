resource "azurerm_policy_definition" "aks_diagnostic_settings" {
  count = var.enable_aks_logs ? 1 : 0

  policy_type = "Custom"
  mode        = "Indexed"

  name         = format("cyngular-%s-aks-def", var.client_name)
  display_name = "Cyngular ${var.client_name} AKS Clusters Diagnostic Settings Definition"
  description  = "Ensures that AKS clusters have diagnostic settings configured to send logs to the specified storage account."

  management_group_id = "/providers/Microsoft.Management/managementGroups/${local.mgmt_group_id}"

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.ContainerService/managedClusters"
        },
        {
          field = "location"
          in    = "[parameters('ClientLocations')]"
        }
      ]
    },
    then = {
      effect = "DeployIfNotExists"
      details = {
        type = "Microsoft.ContainerService/managedClusters/providers/Microsoft.Insights/diagnosticSettings",
        # existenceScope = "resourceGroup"
        roleDefinitionIds = [
          "${azurerm_role_definition.policy_assignment_def[0].role_definition_resource_id}",
          "/providers/Microsoft.Authorization/roleDefinitions/749f88d5-cbae-40b8-bcfc-e573ddc772fa", // Monitoring Contributor
          "/providers/Microsoft.Authorization/roleDefinitions/17d1049b-9a84-46fb-8f53-869881c3d3ab", // Storage Account Contributor
        ],
        existenceCondition = {
          count = {
            field = "Microsoft.Insights/diagnosticSettings/logs[*]",
            where = {
              allOf = [
                {
                  field  = "Microsoft.Insights/diagnosticSettings/logs[*].category",
                  in    = ["kube-audit", "kube-apiserver"]
                },
                {
                  field  = "Microsoft.Insights/diagnosticSettings/logs[*].enabled",
                  equals = true
                },
                {
                  field  = "Microsoft.Insights/diagnosticSettings/storageAccountId"
                  equals = "[parameters('storageAccountIds')[field('location')]]"
                }
              ]
            }
          },
          equals = 2
          # allOf = [
          #   {
          #     field  = "Microsoft.Insights/diagnosticSettings/logs[*].category"
          #     equals = "kube-audit"
          #   },
          #   {
          #     field  = "Microsoft.Insights/diagnosticSettings/logs[*].enabled"
          #     equals = "true"
          #   },
          #   {
          #     field  = "Microsoft.Insights/diagnosticSettings/storageAccountId"
          #     exists = true
          #   }
          # ]
        }
        deployment = {
          properties = {
            mode = "incremental"
            parameters = {
              resourceName = {
                value = "[field('name')]"
              }
              resourceId = {
                value = "[field('id')]"
              }
              location = {
                value = "[field('location')]"
              }
              storageAccountId = {
                value = "[parameters('StorageAccountIds')[field('location')]]"
              }
            }
            template = {
              "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
              contentVersion = "3.0.1.0"
              parameters = {
                resourceName = {
                  type = "string"
                }
                resourceId = {
                  type = "string"
                }
                location = {
                  type = "string"
                }
                storageAccountId = {
                  type = "string"
                }
              }
              resources = [
                {
                  type       = "Microsoft.Insights/diagnosticSettings"
                  apiVersion = "2021-05-01-preview"
                  name       = "CyngularDiagnostic" // ?s
                  # name       = "[concat(parameters('resourceName'), '-AKS-DS')]"
                  scope      = "[parameters('resourceId')]"
                  # location = "[parameters('location')]"
                  properties = {
                    storageAccountId = "[parameters('storageAccountId')]"
                    logs = [
                      {
                        category = "kube-audit"
                        enabled  = true
                      },
                      {
                        category = "kube-apiserver"
                        enabled  = true
                      }
                    ]
                  }
                }
              ]
            }
          }
        }
      }
    }
  })
  metadata = jsonencode({
    category = "Cyngular - AKS"
    version = "3.0.1"
  })
  parameters = jsonencode({
    StorageAccountIds = {
      type = "Object"
      metadata = {
        description = "A map of locations to storage account IDs where the logs should be sent."
        displayName = "Storage Account Map"
      }
    }
    ClientLocations = {
      type = "Array"
      metadata = {
        description = "The list of allowed locations for AKS clusters."
        displayName = "Allowed Locations"
      }
    }
  })
}
