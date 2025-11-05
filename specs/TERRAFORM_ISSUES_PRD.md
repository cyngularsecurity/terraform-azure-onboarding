# Terraform Configuration Issues - Product Requirements Document

## Executive Summary

This PRD documents critical issues, structural problems, and edge cases identified in the Azure onboarding Terraform configuration. Issues are categorized by severity with multiple fix options provided for each.

## Issue Categories

### 🔴 **CRITICAL - Immediate Action Required**
### 🟡 **HIGH - Should Fix Soon** 
### 🟠 **MEDIUM - Technical Debt**
### 🔵 **LOW - Best Practices**

---

## 🔴 CRITICAL ISSUES

### 1. Storage Account Naming Collision Risk
**Location**: `/modules/Cyngular/StorageAccount.tf:3`
**Impact**: Deployment failures due to non-unique storage account names globally

#### Current Code:
```terraform
name = lower(substr("${var.client_name}${each.key}${var.suffix}", 0, 23))
```

#### Problems:
- No validation for global uniqueness
- Similar location names could create identical results
- Truncation to 23 chars may cause collisions

#### Fix Options:

**Option A: Enhanced Suffix Strategy (Recommended)**
```terraform
# In Random.tf
resource "random_string" "storage_suffix" {
  for_each = toset(var.locations)
  length   = 6
  upper    = false
  numeric  = true
  special  = false
}

# In StorageAccount.tf
name = lower(substr("${var.client_name}${each.key}${random_string.storage_suffix[each.key].result}", 0, 24))
```

**Option B: Hash-based Naming**
```terraform
locals {
  storage_names = {
    for loc in var.locations : loc => lower(substr(
      "${var.client_name}${loc}${substr(sha256("${var.client_name}-${loc}-${timestamp()}"), 0, 6)}", 
      0, 24
    ))
  }
}

resource "azurerm_storage_account" "cyngular_sa" {
  for_each = toset(var.locations)
  name     = local.storage_names[each.key]
  # ...
}
```

**Option C: Validation-First Approach**
```terraform
# Add to Vars.tf
locals {
  storage_account_names = [
    for loc in var.locations : lower(substr("${var.client_name}${loc}${random_string.suffix.result}", 0, 24))
  ]
}

variable "locations" {
  # existing config...
  
  validation {
    condition = length(local.storage_account_names) == length(distinct(local.storage_account_names))
    error_message = "Generated storage account names are not unique. Please adjust client_name or locations."
  }
  
  validation {
    condition = alltrue([
      for name in local.storage_account_names : 
      can(regex("^[a-z0-9]{3,24}$", name))
    ])
    error_message = "Storage account names must be 3-24 characters and contain only lowercase letters and numbers."
  }
}
```

### 2. Function Storage Account Missing Suffix
**Location**: `/modules/function/AppRelated.tf:18`
**Impact**: Naming conflicts across deployments

#### Current Code:
```terraform
name = lower(substr("cyngularfunc${var.client_name}", 0, 23))
```

#### Fix Options:

**Option A: Add Suffix (Recommended)**
```terraform
name = lower(substr("func${var.client_name}${var.suffix}", 0, 24))
```

**Option B: Location-based Naming**
```terraform
name = lower(substr("func${var.client_name}${replace(var.main_location, "-", "")}${substr(var.suffix, 0, 4)}", 0, 24))
```

---

## 🟡 HIGH PRIORITY ISSUES

### 3. Missing main_location Validation
**Location**: `/Vars.tf:45-49`
**Impact**: Runtime failures if main_location not in locations list

#### Current Code:
```terraform
# validation {
#   condition     = contains(var.locations, var.main_location)
#   error_message = "The main location must be one of the locations specified in the locations variable."
# }
```

#### Fix Options:

**Option A: Uncomment and Enhance (Recommended)**
```terraform
variable "main_location" {
  type        = string
  description = "The Main location for Storage Account deployment"
  default     = ""

  validation {
    condition     = var.main_location == "" || contains(var.locations, var.main_location)
    error_message = "The main location must be one of the locations specified in the locations variable."
  }
  
  validation {
    condition = var.main_location == "" || contains(local.valid_locations, var.main_location)
    error_message = "The main location must be a valid Azure location."
  }
}
```

**Option B: Auto-selection with Validation**
```terraform
locals {
  main_location_validated = var.main_location != "" ? var.main_location : (
    length(var.locations) > 0 ? var.locations[0] : null
  )
}

# Add check in main module
resource "null_resource" "validate_main_location" {
  count = local.main_location_validated == null ? "ERROR: No valid main location" : 0
}
```

### 4. Application Insights Location Compatibility
**Location**: `/modules/function/AppRelated.tf:52-57`
**Impact**: Function logging failures in unsupported regions

#### Fix Options:

**Option A: Cross-validation (Recommended)**
```terraform
# Add to function module Vars.tf
variable "allow_function_logging" {
  description = "allow function logging"
  type        = bool
  
  validation {
    condition = !var.allow_function_logging || !contains(var.app_insights_unsupported_locations, var.main_location)
    error_message = "Application Insights logging is not supported in ${var.main_location}. Set allow_function_logging=false or choose a different main_location."
  }
}
```

**Option B: Automatic Fallback**
```terraform
locals {
  app_insights_location = contains(var.app_insights_unsupported_locations, var.main_location) ? 
    "westeurope" : var.main_location
    
  effective_logging_enabled = var.allow_function_logging && 
    !contains(var.app_insights_unsupported_locations, var.main_location)
}

resource "azurerm_application_insights" "func_azure_insights" {
  count    = local.effective_logging_enabled ? 1 : 0
  location = local.app_insights_location
  # ...
}
```

**Option C: Warning System**
```terraform
resource "null_resource" "app_insights_warning" {
  count = var.allow_function_logging && contains(var.app_insights_unsupported_locations, var.main_location) ? 1 : 0
  
  provisioner "local-exec" {
    command = "echo 'WARNING: Application Insights not supported in ${var.main_location}. Logging disabled.'"
  }
}
```

---

## 🟠 MEDIUM PRIORITY ISSUES

### 5. Empty Locations Array Handling
**Location**: Multiple files using `toset(var.locations)`
**Impact**: No resources created, confusing behavior

#### Fix Options:

**Option A: Validation (Recommended)**
```terraform
variable "locations" {
  # existing config...
  
  validation {
    condition     = length(var.locations) > 0
    error_message = "At least one location must be specified."
  }
  
  validation {
    condition     = length(var.locations) <= 10
    error_message = "Maximum of 10 locations allowed to prevent resource limits."
  }
}
```

**Option B: Default Location Fallback**
```terraform
locals {
  effective_locations = length(var.locations) > 0 ? var.locations : ["eastus"]
}

# Use local.effective_locations instead of var.locations
```

### 6. Hard-coded Function ZIP URL
**Location**: `/modules/function/Locals.tf:9`
**Impact**: Environment inflexibility, single point of failure

#### Fix Options:

**Option A: Environment-based URLs (Recommended)**
```terraform
# Add to function module Vars.tf
variable "function_zip_url" {
  description = "URL for the function deployment zip file"
  type        = string
  default     = "https://cyngular-onboarding-templates.s3.us-east-1.amazonaws.com/azure/cyngular_func.zip"
  
  validation {
    condition     = can(regex("^https://", var.function_zip_url))
    error_message = "Function zip URL must be a valid HTTPS URL."
  }
}

# In Locals.tf
locals {
  func_zip_url = var.function_zip_url
}
```

**Option B: Multi-region URLs**
```terraform
locals {
  region_zip_urls = {
    "eastus"     = "https://cyngular-onboarding-templates-us-east-1.s3.amazonaws.com/azure/cyngular_func.zip"
    "westeurope" = "https://cyngular-onboarding-templates-eu-west-1.s3.amazonaws.com/azure/cyngular_func.zip"
    "default"    = "https://cyngular-onboarding-templates.s3.us-east-1.amazonaws.com/azure/cyngular_func.zip"
  }
  
  func_zip_url = lookup(local.region_zip_urls, var.main_location, local.region_zip_urls["default"])
}
```

### 7. Resource Dependency Issues
**Location**: `/modules/function/FunctionApp.tf:49-56`
**Impact**: Race conditions during deployment/destruction

#### Fix Options:

**Option A: Explicit Dependencies (Recommended)**
```terraform
resource "azurerm_linux_function_app" "function_service" {
  # existing config...
  
  depends_on = [
    local_sensitive_file.zip_file,
    azurerm_role_assignment.func_assigment_custom_mgmt,
    azurerm_role_assignment.func_assigment_reader_mgmt,
    azurerm_role_assignment.cyngular_sa_contributor,
    azurerm_role_assignment.cyngular_blob_owner,
    azurerm_role_assignment.cyngular_main_storage_table_contributor,
    azurerm_application_insights.func_azure_insights,  # Add missing dependency
    azurerm_storage_account.func_storage_account       # Add missing dependency
  ]
}
```

**Option B: Conditional Dependencies**
```terraform
locals {
  function_dependencies = concat([
    azurerm_role_assignment.func_assigment_custom_mgmt.id,
    azurerm_role_assignment.func_assigment_reader_mgmt.id,
    azurerm_storage_account.func_storage_account.id
  ], var.allow_function_logging ? [azurerm_application_insights.func_azure_insights[0].id] : [])
}

resource "azurerm_linux_function_app" "function_service" {
  # existing config...
  
  depends_on = [local_sensitive_file.zip_file]
  
  lifecycle {
    replace_triggered_by = local.function_dependencies
  }
}
```

---

## 🔵 LOW PRIORITY - BEST PRACTICES

### 8. Inconsistent Resource Naming Patterns
**Location**: Multiple files
**Impact**: Maintenance confusion, inconsistent infrastructure

#### Fix Options:

**Option A: Standardized Naming Module (Recommended)**
```terraform
# Create modules/naming/main.tf
locals {
  naming = {
    resource_group    = "${var.prefix}-rg"
    storage_account   = lower(replace("${var.prefix}sa${var.suffix}", "/[^a-z0-9]/", ""))
    function_app      = "${var.prefix}-func"
    service_plan      = "${var.prefix}-asp"
    app_insights      = "${var.prefix}-ai"
    log_workspace     = "${var.prefix}-law"
    user_identity     = "${var.prefix}-uai"
  }
  
  # Ensure storage account names are valid
  validated_names = {
    for k, v in local.naming : k => k == "storage_account" ? 
      substr(v, 0, min(24, length(v))) : v
  }
}

output "names" {
  value = local.validated_names
}
```

**Option B: Naming Convention Variables**
```terraform
# Add to root Vars.tf
variable "naming_convention" {
  description = "Naming convention pattern"
  type        = string
  default     = "{prefix}-{resource}-{suffix}"
  
  validation {
    condition = can(regex("\\{prefix\\}", var.naming_convention))
    error_message = "Naming convention must include {prefix} placeholder."
  }
}

locals {
  name_template = replace(replace(
    var.naming_convention, 
    "{prefix}", local.resource_prefix),
    "{suffix}", local.random_suffix
  )
}
```

### 9. Missing Resource Locks
**Location**: All critical resources
**Impact**: Accidental deletion risk

#### Fix Options:

**Option A: Conditional Resource Locks (Recommended)**
```terraform
# Add to root Vars.tf
variable "enable_deletion_protection" {
  description = "Enable deletion protection for critical resources"
  type        = bool
  default     = true
}

# Add to critical resources
resource "azurerm_management_lock" "storage_account_lock" {
  for_each   = var.enable_deletion_protection ? azurerm_storage_account.cyngular_sa : {}
  name       = "CanNotDelete"
  scope      = each.value.id
  lock_level = "CanNotDelete"
  notes      = "Prevent accidental deletion of critical storage account"
}
```

**Option B: Environment-based Locks**
```terraform
locals {
  lock_level_map = {
    "prod" = "CanNotDelete"
    "stg"  = "ReadOnly" 
    "dev"  = null
  }
  
  should_lock = local.lock_level_map[var.environment] != null
}
```

### 10. Terraform Version Constraints
**Location**: Missing in all modules
**Impact**: Version drift, compatibility issues

#### Fix Options:

**Option A: Add Version Constraints (Recommended)**
```terraform
# Add to each module
terraform {
  required_version = ">= 1.9.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"  
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
```

## Implementation Priority Matrix

| Issue | Severity | Effort | Risk | Priority |
|-------|----------|--------|------|----------|
| Storage Account Naming | 🔴 Critical | Medium | High | 1 |
| Function Storage Suffix | 🔴 Critical | Low | High | 2 |
| main_location Validation | 🟡 High | Low | Medium | 3 |
| App Insights Validation | 🟡 High | Medium | Medium | 4 |
| Empty Locations Handling | 🟠 Medium | Low | Low | 5 |
| Hard-coded URLs | 🟠 Medium | Low | Low | 6 |
| Resource Dependencies | 🟠 Medium | Medium | Medium | 7 |
| Naming Consistency | 🔵 Low | High | Low | 8 |
| Resource Locks | 🔵 Low | Medium | Low | 9 |
| Version Constraints | 🔵 Low | Low | Low | 10 |

## Recommended Implementation Phases

### Phase 1: Critical Fixes (Week 1)
1. Fix storage account naming collision (Issue #1)
2. Add suffix to function storage account (Issue #2)
3. Enable main_location validation (Issue #3)

### Phase 2: High Priority (Week 2)
4. Add Application Insights location validation (Issue #4)
5. Add empty locations validation (Issue #5)
6. Fix resource dependencies (Issue #7)

### Phase 3: Medium Priority (Week 3-4)
7. Parameterize function ZIP URL (Issue #6)
8. Add version constraints (Issue #10)

### Phase 4: Best Practices (Future)
9. Implement consistent naming patterns (Issue #8)
10. Add resource locks (Issue #9)

## Testing Strategy

For each fix, implement this testing approach:

1. **Unit Tests**: Validate with `terraform validate` and `terraform plan`
2. **Integration Tests**: Deploy to dev environment
3. **Edge Case Testing**: Test with boundary conditions (empty arrays, unsupported locations)
4. **Regression Testing**: Ensure existing deployments still work
5. **Documentation Updates**: Update README and variable descriptions

## Success Metrics

- ✅ All `terraform validate` checks pass
- ✅ All `terraform plan` operations succeed
- ✅ No naming collision errors in multi-region deployments  
- ✅ Proper validation error messages for invalid inputs
- ✅ Clean deployment and destruction cycles
- ✅ Consistent naming across all resources








  | Provider                      | Required For                                              |
  |-------------------------------|-----------------------------------------------------------|
  | Microsoft.Storage             | Storage accounts (multiple across locations)              |
  | Microsoft.Web                 | Azure Function App and App Service Plan                   |
  | Microsoft.Insights            | Application Insights, Diagnostic Settings, AAD monitoring |
  | Microsoft.OperationalInsights | Log Analytics Workspace                                   |
  | Microsoft.ManagedIdentity     | User Assigned Identity for function                       |


  | Provider                   | Required When           | Used For                        |
  |----------------------------|-------------------------|---------------------------------|
  | Microsoft.Network          | enable_flow_logs = true | NSG Flow Logs, Network Watchers |
  | Microsoft.ContainerService | enable_aks_logs = true  | AKS cluster diagnostic settings |




---
Microsoft.Web
Microsoft.Insights
Microsoft.OperationalInsights
Microsoft.ManagedIdentity
Microsoft.Authorization
Microsoft.Resources
---
Microsoft.Network
Microsoft.ContainerService
---
## check if registered
az provider show --namespace ${RESOURCE_PROVIDER} --query "registrationState"
## register if not
az provider register --namespace ${RESOURCE_PROVIDER}



