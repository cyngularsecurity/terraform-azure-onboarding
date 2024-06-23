
resource "azurerm_policy_definition" "audit_event_diagnostic_settings" {
  count                = var.enable_audit_events_logs ? 1 : 0

  name = format("cyngular-%s-%s-audit-event-def", var.client_name, var.subscription_name)
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Cyngular ${var.client_name} Audit Event - over resources in sub ${var.subscription_name}"
  description  = "Cyngular diagnostic settings deployment for resources various categories"
  management_group_id      = "/providers/Microsoft.Management/managementGroups/${data.azuread_client_config.current.tenant_id}"

  metadata = jsonencode({ category = "Monitoring" })
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
        description = "The list of allowed locations for Resources."
        displayName = "Allowed Locations"
      }
    }
    blacklistedTypes = {
      type = "Array"
      metadata = {
        displayName = "Resource Types"
        description = "List of Azure resource types not supporting diagnostics settings."
      }
    }
    typeListA = {
      type = "Array",
      metadata = {
        description = "List of resource types to check for AllLogs category"
      }
    },
    typeListB = {
      type = "Array",
      metadata = {
        description = "List of resource types to check for AllLogs and Audit categories"
      }
    }
  })
  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          not = {
            field  = "type"
            in = "[parameters('blacklistedTypes')]"
            # notin = "[concat(parameters('typeListA'), parameters('typeListB'), parameters('blacklistedTypes'))]"
          }
        },
        # {
        #   field  = "type"
        #   notin = "[parameters('blacklistedTypes')]"
        #   # notin = "[concat(parameters('typeListA'), parameters('typeListB'), parameters('blacklistedTypes'))]"
        # },
        {
          allOf = [
            {
              anyOf = [
                {
                  field  = "type"
                  in = "[parameters('typeListA')]"
                },
                {
                  field  = "type"
                  in = "[parameters('typeListB')]"
                }
              ]
            },
            {
              field  = "location"
              in = "[parameters('ClientLocations')]"
            }
          ]
        }
      ]
    }
    then = {
      effect = "deployIfNotExists"
      details = {
        roleDefinitionIds = [
          "/providers/Microsoft.Authorization/roleDefinitions/ccca81f6-c8dc-45e2-8833-a5e13f9ae238",  // Monitoring Contributor
          "/providers/Microsoft.Authorization/roleDefinitions/17d1049b-9a84-46fb-8f53-869881c3d3ab"   // Storage Account Contributor
        ]
        type = "Microsoft.Insights/diagnosticSettings"
        existenceCondition = {
          anyOf = [
            {
              allOf = [
                {
                  field = "type",
                  in    = "[parameters('typeListA')]"
                },
                {
                  count = {
                    field = "Microsoft.Insights/diagnosticSettings/logs[*]",
                    where = {
                      allOf = [
                        {
                          field  = "Microsoft.Insights/diagnosticSettings/logs[*].enabled",
                          equals = true
                        },
                        {
                          field  = "Microsoft.Insights/diagnosticSettings/logs[*].categoryGroup",
                          equals = "AllLogs"
                        },
                        {
                          field  = "Microsoft.Insights/diagnosticSettings/storageAccountId"
                          equals =  "[parameters('storageAccountIds')[field('location')]]"
                          # exists = true
                        }
                      ]
                    }
                  },
                  equals = 1
                }
              ]
            },
            {
              allOf = [
                {
                  field = "type",
                  in    = "[parameters('typeListB')]"
                },
                {
                  count = {
                    field = "Microsoft.Insights/diagnosticSettings/logs[*]",
                    where = {
                      allOf = [
                        {
                          field  = "Microsoft.Insights/diagnosticSettings/logs[*].enabled",
                          equals = true
                        },
                        {
                          field  = "Microsoft.Insights/diagnosticSettings/logs[*].categoryGroup",
                          in    = ["AllLogs", "Audit"]
                        },
                        {
                          field  = "Microsoft.Insights/diagnosticSettings/storageAccountId"
                          equals =  "[parameters('storageAccountIds')[field('location')]]"
                        }
                      ]
                    }
                  },
                  equals = 2
                }
              ]
            },
            {
              allOf = [
                {
                  not = {
                    field  = "type"
                    in = "[concat(parameters('typeListA'), parameters('typeListB'))]"
                  }
                },
                {
                  count = {
                    field = "Microsoft.Insights/diagnosticSettings/logs[*]",
                    where = {
                      allOf = [
                        {
                          field  = "Microsoft.Insights/diagnosticSettings/logs[*].enabled",
                          equals = true
                        },
                        {
                          field  = "Microsoft.Insights/diagnosticSettings/logs[*].category",
                          equals = "AuditEvent"
                        },
                        {
                          field  = "Microsoft.Insights/diagnosticSettings/storageAccountId"
                          equals =  "[parameters('storageAccountIds')[field('location')]]"
                        }
                      ]
                    }
                  },
                  equals = 1
                }
              ]
            }
          ]
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
              logsConfiguration = {
                value = "[if(contains(parameters('typeListA'), field('type')), 'AllLogs', if(contains(parameters('typeListB'), field('type')), 'AllLogs,Audit', 'AuditEvent'))]"
              }
            }
            template = {
              "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
              contentVersion = "1.3.0.0"
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
                logsConfiguration = {
                  type = "list"
                }
              }
              resources = [
                {
                  type       = "Microsoft.Insights/diagnosticSettings"
                  apiVersion = "2021-05-01-preview"
                  name       = "[concat(parameters('resourceName'), '-diagnostics')]"
                  # location   = "[parameters('location')]"
                  scope = "[parameters('resourceId')]"
                  properties = {
                    storageAccountId = "[parameters('storageAccountId')]"
                    logs = [
                      {
                        categoryGroup = "[parameters('logsConfiguration')]"
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
}