# resource "azurerm_management_group_policy_exemption" "mgmt_group_exemption" {
#   name                = "Cyngular-AE-Exempt"
#   display_name        = "Cyngular ${var.client_name} Audit Event Black Listed"
#   description         = "Cyngular Exempted Black Listed resources from policy enforcement within the management group."

#   # scope               = data.azurerm_management_group.example.id
#   exemption_category  = "Waiver" // "Mitigated"
#   policy_assignment_id = azurerm_policy_set_definition.monitoring_initiative.id

#   management_group_id = "/providers/Microsoft.Management/managementGroups/${local.mgmt_group_id}"

#   metadata = jsonencode({
#     enforced = "true",
#     reason = "For Non Compiant Resources Types."
#   })

#   # expires_on = "2050-12-31"

#   policy_definition_reference_ids = [
#     azurerm_policy_definition.policy_a.id,
#     azurerm_policy_definition.policy_b.id,
#     azurerm_policy_definition.default_policy.id
#   ]
# }