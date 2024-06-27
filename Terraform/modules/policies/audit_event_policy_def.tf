resource "azurerm_policy_set_definition" "audit_event_initiative" {
  count = var.enable_audit_events_logs ? 1 : 0

  policy_type  = "Custom"

  name         = "Cyngular-AE-Initiative"
  display_name = "Cyngular ${var.client_name} Audit Event Initiative"

  description         = "Cyngular diagnostic settings deployment for resources various categories"
  management_group_id = "/providers/Microsoft.Management/managementGroups/${local.mgmt_group_id}"

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.audit_event_ds_list_a[count.index].id
    parameter_values     = <<VALUE
    {
      "StorageAccountIds": {"value": "[parameters('StorageAccountIds')]"},
      "ClientLocations": {"value": "[parameters('ClientLocations')]"},
      "typeListA": {"value": "[parameters('typeListA')]"}
    }
    VALUE
  }
  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.audit_event_ds_list_b[count.index].id
    parameter_values     = <<VALUE
    {
      "StorageAccountIds": {"value": "[parameters('StorageAccountIds')]"},
      "ClientLocations": {"value": "[parameters('ClientLocations')]"},
      "typeListB": {"value": "[parameters('typeListB')]"}
    }
    VALUE
  }
  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.audit_event_ds_audit_event[count.index].id
    parameter_values     = <<VALUE
    {
      "StorageAccountIds": {"value": "[parameters('StorageAccountIds')]"},
      "ClientLocations": {"value": "[parameters('ClientLocations')]"},
      "typeListA": {"value": "[parameters('typeListA')]"},
      "typeListB": {"value": "[parameters('typeListB')]"}
    }
    VALUE
  }

  parameters = jsonencode({
  #   # "BlacklistedTypes"  = { value = local.resource_types.black_listed },
    ClientLocations   = {
      type = "Array"
      metadata = {
        displayName = "Client Locations"
        description = "List of allowed locations"
      }
      defaultValue = var.client_locations
    }
    StorageAccountIds = {
      type = "Object"
      metadata = {
        displayName = "Storage Account IDs"
        description = "Map of storage account IDs"
      }
      defaultValue = merge(var.default_storage_accounts, { disabled = "empty" })
    }
    typeListA = {
      type = "Array"
      metadata = {
        displayName = "Type List A"
        description = "List of resource types for group A"
      }
      defaultValue = local.resource_types.list_a
    }
    typeListB = {
      type = "Array"
      metadata = {
        displayName = "Type List B"
        description = "List of resource types for group B"
      }
      defaultValue = local.resource_types.list_b
    }
  })
  metadata = jsonencode({
    category = "Cyngular - Audit Event"
    version = "3.0.1"
  })
}

resource "azurerm_policy_definition" "audit_event_ds_list_a" {
  count = var.enable_audit_events_logs ? 1 : 0

  policy_type = "Custom"
  mode        = "Indexed"

  name                = "Cyngular-AE-ListA-def"
  display_name        = "Cyngular ${var.client_name} Audit Event Definition List A"
  description         = "Cyngular diagnostic settings deployment for resources various categories"
  management_group_id = "/providers/Microsoft.Management/managementGroups/${local.mgmt_group_id}"

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field = "type",
          in    = "[parameters('typeListA')]"
        },
        {
          field = "location",
          in    = "[parameters('ClientLocations')]"
        }
      ]
    },
    then = {
      effect = "DeployIfNotExists",
      details = {
        type  = "Microsoft.Insights/diagnosticSettings",
        roleDefinitionIds = [
          "${azurerm_role_definition.policy_assignment_def[0].role_definition_resource_id}",
          "/providers/Microsoft.Authorization/roleDefinitions/749f88d5-cbae-40b8-bcfc-e573ddc772fa", // Monitoring Contributor
          "/providers/Microsoft.Authorization/roleDefinitions/17d1049b-9a84-46fb-8f53-869881c3d3ab",  // Storage Account Contributor
        ],
        existenceCondition = {
          anyOf = [
            {
              allOf = [
                { // to deploy AllLogs category diagnostic settings on supported, from list A -- 1
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
                          equals = "[parameters('storageAccountIds')[field('location')]]"
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
                  name       = "CyngularDiagnostics"
                  # name       = "[concat(parameters('resourceName'), '-diagnostics')]"
                  location   = "[parameters('location')]"
                  scope = "[parameters('resourceId')]"
                  properties = {
                    storageAccountId = "[parameters('storageAccountId')]"
                    logs = [
                      {
                        categoryGroup = "AllLogs"
                        enabled       = true
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
    category = "Cyngular - Audit Event"
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
        description = "The list of allowed locations for Resources."
        displayName = "Allowed Locations"
      }
    }
    # blacklistedTypes = {
    #   type = "Array"
    #   metadata = {
    #     displayName = "Resource Types"
    #     description = "List of Azure resource types not supporting diagnostics settings."
    #   }
    # }
    typeListA = {
      type = "Array",
      metadata = {
        description = "List of resource types to check for AllLogs category"
      }
    }
  })
}

resource "azurerm_policy_definition" "audit_event_ds_list_b" {
  count = var.enable_audit_events_logs ? 1 : 0

  policy_type = "Custom"
  mode        = "Indexed"

  name                = "Cyngular-AE-ListB-def"
  display_name        = "Cyngular ${var.client_name} Audit Event Definition List B"
  description         = "Cyngular diagnostic settings deployment for resources various categories"
  management_group_id = "/providers/Microsoft.Management/managementGroups/${local.mgmt_group_id}"

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field = "type",
          in    = "[parameters('typeListB')]"
        },
        {
          field = "location",
          in    = "[parameters('ClientLocations')]"
        }
      ]
    },
    then = {
      effect = "DeployIfNotExists",
      details = {
        type  = "Microsoft.Insights/diagnosticSettings",
        roleDefinitionIds = [
          "${azurerm_role_definition.policy_assignment_def[0].role_definition_resource_id}",
          "/providers/Microsoft.Authorization/roleDefinitions/749f88d5-cbae-40b8-bcfc-e573ddc772fa", // Monitoring Contributor
          "/providers/Microsoft.Authorization/roleDefinitions/17d1049b-9a84-46fb-8f53-869881c3d3ab",  // Storage Account Contributor
        ],
        existenceCondition = {
          anyOf = [
            {
              allOf = [
                { // to deploy AllLogs, Audit categories diagnostic settings on supported, from list B -- 2
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
                          field = "Microsoft.Insights/diagnosticSettings/logs[*].categoryGroup",
                          in    = ["AllLogs", "Audit"]
                        },
                        {
                          field  = "Microsoft.Insights/diagnosticSettings/storageAccountId"
                          equals = "[parameters('storageAccountIds')[field('location')]]"
                        }
                      ]
                    }
                  },
                  equals = 2
                }
              ]
            },
          ]
        },
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
                  name       = "CyngularDiagnostics"
                  # name       = "[concat(parameters('resourceName'), '-diagnostics')]"
                  location   = "[parameters('location')]"
                  scope = "[parameters('resourceId')]"
                  properties = {
                    storageAccountId = "[parameters('storageAccountId')]"
                    logs = [
                      {
                        categoryGroup = "AllLogs"
                        enabled       = true
                      },
                      {
                        categoryGroup = "Audit"
                        enabled       = true
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
    category = "Cyngular - Audit Event"
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
        description = "The list of allowed locations for Resources."
        displayName = "Allowed Locations"
      }
    }
    typeListB = {
      type = "Array",
      metadata = {
        description = "List of resource types to check for AllLogs and Audit categories"
      }
    }
  })
}

resource "azurerm_policy_definition" "audit_event_ds_audit_event" {
  count = var.enable_audit_events_logs ? 1 : 0

  policy_type = "Custom"
  mode        = "Indexed"

  name                = "Cyngular-AE-default-def"
  display_name        = "Cyngular ${var.client_name} Audit Event Definition Default"
  description         = "Cyngular diagnostic settings deployment for resources various categories"
  management_group_id = "/providers/Microsoft.Management/managementGroups/${local.mgmt_group_id}"

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field = "type",
          notIn    = "[concat(parameters('typeListA'), parameters('typeListB'))]"
        },
        {
          field = "location",
          in    = "[parameters('ClientLocations')]"
        }
      ]
    },
    then = {
      effect = "DeployIfNotExists",
      details = {
        type  = "Microsoft.Insights/diagnosticSettings",
        roleDefinitionIds = [
          "${azurerm_role_definition.policy_assignment_def[0].role_definition_resource_id}",
          "/providers/Microsoft.Authorization/roleDefinitions/749f88d5-cbae-40b8-bcfc-e573ddc772fa", // Monitoring Contributor
          "/providers/Microsoft.Authorization/roleDefinitions/17d1049b-9a84-46fb-8f53-869881c3d3ab", // Storage Account Contributor
        ],
        existenceCondition = {
          anyOf = [
            {
              allOf = [
                { // to deploy AuditEvent category diagnostic settings on all other resources supporting DS, if are not in specified lists -- Default
                  not = {
                    field = "type"
                    in    = "[concat(parameters('typeListA'), parameters('typeListB'))]"
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
                          equals = "[parameters('storageAccountIds')[field('location')]]"
                        }
                      ]
                    }
                  },
                  equals = 1
                }
              ]
            }
          ]
        },
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
                  name       = "CyngularDiagnostics"
                  name       = "[concat(parameters('resourceName'), '-diagnostics')]"
                  location   = "[parameters('location')]"
                  scope = "[parameters('resourceId')]"
                  properties = {
                    storageAccountId = "[parameters('storageAccountId')]"
                    logs = [
                      {
                        categoryGroup = "AuditEvent"
                        enabled       = true
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
    category = "Cyngular - Audit Event"
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
        description = "The list of allowed locations for Resources."
        displayName = "Allowed Locations"
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
}