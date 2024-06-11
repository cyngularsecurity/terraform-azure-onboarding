
resource "azurerm_subscription_policy_assignment" "auditvms" {
  name                 = "audit-vm-manageddisks"
  subscription_id      = var.cust_scope
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/06a78e20-9358-41c9-923c-fb736d382a4d"
  description          = "Shows all virtual machines not using managed disks"
  display_name         = "Audit VMs without managed disks assignment"
}

variable "cust_scope" {
  default = "{scope}"
}

output "assignment_id" {
  value = azurerm_subscription_policy_assignment.auditvms.id
}

# module "global_core" {
#   source = "./modules/azure-policy-initiative"

#   assignment = {
#     assignments = [{
#       id   = data.azurerm_resource_group.this.id
#       name = "DefaultRG"
#     }]
#     scope = "rg"
#   }

#   exemptions = [{
#     assignment_reference = "DefaultRG"
#     category             = "Mitigated"
#     id                   = data.azurerm_resource_group.this.id
#     risk_id              = "R-001"
#     scope                = "rg"
#   }]

#   environment           = "dev"
#   initiative_definition = format("%s/initiatives/core.yaml", path.module)
# }
