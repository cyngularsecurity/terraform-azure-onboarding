# resource "terraform_data" "validate_access" {
#   triggers_replace = {
#     root_mg_id = local.root_mg_id
#   }

#   lifecycle {
#     precondition {
#       condition     = local.root_mg_id != null
#       error_message = "Cannot access root management group. Ensure Management Groups feature is enabled."
#     }
#   }
# }

data "azurerm_role_assignments" "current_user" {
  scope = "/providers/Microsoft.Management/managementGroups/${local.mgmt_group_id}"
}

locals {
  required_role_ids = [
    "8e3af657-a8ff-443c-a75c-2fe8c4bcb635", // Owner
    "b24988ac-6180-42a0-ab88-20f7382dd24c", // Contributor
  ]

  has_required_role = anytrue([
    for assignment in data.azurerm_role_assignments.current_user.role_assignments :
    contains(local.required_role_ids, basename(assignment.role_definition_id))
  ])
}

check "mgmt_groups_enabled" {
  assert {
    condition     = local.root_mg_id != null
    error_message = "Cannot access root management group. Ensure Management Groups feature is enabled."
  }
}

# Check block (Terraform 1.5+)
check "permissions_check" {
  assert {
    condition     = local.has_required_role
    error_message = "Missing required permissions. The current identity must have at least one of: Owner or Contributor on the Root Management Group ${local.mgmt_group_id}."
  }
}