data "azurerm_role_assignments" "current_user" {
  scope = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
}

locals {
  has_required_role = anytrue([
    for assignment in data.azurerm_role_assignments.current_user.role_assignments :
    contains(["Owner", "Contributor"], assignment.role_assignment_name)
  ])
}

# Check block (Terraform 1.5+)
check "permissions_check" {
  assert {
    condition     = local.has_required_role
    # error_message = "Current user must have Owner or Contributor role on subscription."
    error_message = "Missing required subscription role. The current identity must have at least one of: Owner or Contributor on the subscription ${data.azurerm_subscription.current.subscription_id}."
  }
}

resource "terraform_data" "validate_access" {
  triggers_replace = {
    root_mg_id = local.root_mg_id
  }

  lifecycle {
    precondition {
      condition     = local.root_mg_id != null
      error_message = "Cannot access root management group. Ensure Management Groups feature is enabled."
    }
  }
}