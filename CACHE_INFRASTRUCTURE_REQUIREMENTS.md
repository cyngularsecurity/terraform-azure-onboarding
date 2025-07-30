# Cache System Infrastructure Requirements

## Overview

This document outlines the infrastructure changes required to support the hybrid cache system implementation in the Cyngular Azure Diagnostic Settings Function. The cache system uses Azure Storage Tables for 24-hour persistent caching and Azure Durable Entities for session-based caching to reduce Azure Monitor API calls by 70-90%.

## 1. Storage Account Requirements

### 1.1 Cache Storage Account

**Purpose**: Dedicated storage account for cache operations to avoid conflicts with diagnostic logs storage.

**Terraform Resource Requirements**:
```hcl
# New storage account specifically for cache operations
resource "azurerm_storage_account" "cache_storage" {
  name                     = "${var.company_name}cachesa${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  # Required for Table service
  account_kind = "StorageV2"
  
  # Enable Table service
  table_properties {
    cors_rule {
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "POST", "PUT", "DELETE"]
      allowed_origins    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }
  }

  tags = {
    Purpose = "DiagnosticSettingsCache"
    Component = "CyngularFunction"
  }
}
```

### 1.2 Storage Account Configuration

**Requirements**:
- **Account Kind**: StorageV2 (required for Table service)
- **Performance Tier**: Standard (sufficient for cache operations)
- **Replication**: LRS (Locally Redundant Storage) - adequate for cache data
- **Access Tier**: Hot (for frequent cache access)
- **Public Access**: Disabled (access via private endpoints if required)

## 2. RBAC Permissions and Role Assignments

### 2.1 User Assigned Identity Permissions

The existing User Assigned Identity requires additional permissions for cache operations:

**Terraform Role Assignments**:
```hcl
# Storage Table Data Contributor role for cache operations
resource "azurerm_role_assignment" "uai_table_contributor" {
  scope                = azurerm_storage_account.cache_storage.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = azurerm_user_assigned_identity.function_identity.principal_id
}

# Alternative: Storage Account Contributor (broader permissions)
# Use if Storage Table Data Contributor is insufficient
resource "azurerm_role_assignment" "uai_storage_contributor" {
  scope                = azurerm_storage_account.cache_storage.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_user_assigned_identity.function_identity.principal_id
}
```

### 2.2 Required Azure Built-in Roles

**Primary Role** (Recommended):
- **Storage Table Data Contributor**: Allows read, write, and delete access to Azure Storage tables and table entities

**Alternative Role** (If broader access needed):
- **Storage Account Contributor**: Full management access to storage account

**Specific Permissions Required**:
- `Microsoft.Storage/storageAccounts/tableServices/tables/read`
- `Microsoft.Storage/storageAccounts/tableServices/tables/write`
- `Microsoft.Storage/storageAccounts/tableServices/tables/delete`
- `Microsoft.Storage/storageAccounts/tableServices/tables/entities/read`
- `Microsoft.Storage/storageAccounts/tableServices/tables/entities/write`
- `Microsoft.Storage/storageAccounts/tableServices/tables/entities/delete`

## 3. Environment Variables Configuration

### 3.1 Required Environment Variables

**New Environment Variables**:
```hcl
# Function App configuration
resource "azurerm_function_app" "cyngular_function" {
  # ... existing configuration ...

  app_settings = {
    # ... existing app_settings ...
    
    # Cache Configuration
    "CACHE_STORAGE_ACCOUNT" = azurerm_storage_account.cache_storage.name
    "enable_cache"          = "true"  # Default: true, set to false to disable
  }
}
```

### 3.2 Environment Variable Details

| Variable | Required | Default | Purpose |
|----------|----------|---------|---------|
| `CACHE_STORAGE_ACCOUNT` | Yes* | None | Storage account name for cache operations |
| `enable_cache` | No | `"true"` | Feature flag to enable/disable cache system |

*Required when `enable_cache` is `"true"` (default)

### 3.3 Terraform Variables

**Add to terraform variables**:
```hcl
variable "enable_cache" {
  description = "Enable diagnostic settings cache system"
  type        = bool
  default     = true
}

variable "cache_storage_replication_type" {
  description = "Replication type for cache storage account"
  type        = string
  default     = "LRS"
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.cache_storage_replication_type)
    error_message = "Cache storage replication type must be a valid Azure storage replication type."
  }
}
```

## 4. Function Runtime Configuration

### 4.1 Python Dependencies

**No Changes Required**: The `azure-data-tables` package is already included in `requirements.txt`:
```
azure-data-tables
```

### 4.2 Function App Configuration

**Host.json - No Changes Required**: Current configuration supports cache operations:
- Function timeout: 10 minutes (adequate for cache operations)
- Concurrency limits: 8 concurrent functions (sufficient)

### 4.3 Application Insights

**Enhanced Monitoring** (Optional but Recommended):
```hcl
# Add cache-specific log analytics queries
resource "azurerm_log_analytics_query_pack_query" "cache_performance" {
  query_pack_id = azurerm_log_analytics_query_pack.function_queries.id
  body          = "traces | where message contains '[CACHE]' | summarize count() by bin(timestamp, 5m)"
  display_name  = "Cache Performance Metrics"
}
```

## 5. Network and Security Configuration

### 5.1 Private Endpoints (Optional)

If the function app uses private endpoints, extend to cache storage:

```hcl
# Private endpoint for cache storage account
resource "azurerm_private_endpoint" "cache_storage_pe" {
  name                = "${azurerm_storage_account.cache_storage.name}-pe"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.function_subnet.id

  private_service_connection {
    name                           = "${azurerm_storage_account.cache_storage.name}-psc"
    private_connection_resource_id = azurerm_storage_account.cache_storage.id
    subresource_names              = ["table"]
    is_manual_connection           = false
  }
}
```

### 5.2 Firewall Rules

**Storage Account Firewall**:
```hcl
resource "azurerm_storage_account_network_rules" "cache_storage_rules" {
  storage_account_id = azurerm_storage_account.cache_storage.id

  default_action             = "Deny"
  ip_rules                   = []
  virtual_network_subnet_ids = [azurerm_subnet.function_subnet.id]
  bypass                     = ["AzureServices"]
}
```

## 6. Monitoring and Alerting

### 6.1 Storage Account Monitoring

**Recommended Metrics to Monitor**:
- Table service availability
- Table service latency
- Table entity count
- Storage account capacity

**Terraform Alert Rules**:
```hcl
# Cache storage availability alert
resource "azurerm_monitor_metric_alert" "cache_storage_availability" {
  name                = "cache-storage-availability"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_storage_account.cache_storage.id]
  description         = "Cache storage account availability alert"

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "Availability"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 99.0
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}
```

### 6.2 Cache Performance Monitoring

**Log Analytics Queries** (for Application Insights):
```kusto
-- Cache Hit Rate
traces
| where message contains "[CACHE]"
| where message contains "Cache check completed"
| extend hits = extract(@"(\d+) hits", 1, message)
| extend misses = extract(@"(\d+) misses", 1, message)
| summarize TotalHits = sum(toint(hits)), TotalMisses = sum(toint(misses))
| extend HitRate = TotalHits * 100 / (TotalHits + TotalMisses)

-- Cache Operations Over Time
traces
| where message contains "[CACHE]"
| summarize count() by bin(timestamp, 5m), operation=extract(@"\[CACHE\] ([^:]+)", 1, message)
| render timechart
```

## 7. Cost Considerations

### 7.1 Storage Costs

**Estimated Monthly Costs** (based on typical usage):
- **Storage capacity**: $0.02-0.05/GB (minimal - cache data is small)
- **Table operations**: $0.0004 per 10,000 operations
- **Data transfer**: Minimal (internal Azure traffic)

**Cost Optimization**:
- Use LRS replication (lowest cost)
- Enable automatic cleanup of expired entries
- Monitor storage usage and adjust retention if needed

### 7.2 Performance vs Cost

**Benefits**:
- 70-90% reduction in Azure Monitor API calls
- Reduced function execution time
- Lower Azure Monitor API costs

**Trade-offs**:
- Additional storage account costs
- Slightly increased complexity

## 8. Deployment Checklist

### 8.1 Pre-Deployment

- [ ] Review existing User Assigned Identity configuration
- [ ] Verify storage account naming conventions
- [ ] Confirm network security requirements
- [ ] Plan cache storage account location/region

### 8.2 Deployment Steps

1. [ ] Create cache storage account with Table service enabled
2. [ ] Assign RBAC permissions to User Assigned Identity
3. [ ] Configure environment variables in Function App
4. [ ] Deploy updated function code
5. [ ] Test cache operations in development environment
6. [ ] Monitor cache performance and hit rates

### 8.3 Post-Deployment Validation

- [ ] Verify cache storage account accessibility
- [ ] Confirm table creation (DiagnosticSettingsCache)
- [ ] Monitor Application Insights for cache operation logs
- [ ] Validate cache hit/miss ratios
- [ ] Test cache behavior during function execution

## 9. Rollback Plan

### 9.1 Emergency Disable

To disable cache system without redeployment:
```hcl
# Set environment variable to disable cache
"enable_cache" = "false"
```

### 9.2 Complete Rollback

1. Remove cache-related environment variables
2. Remove RBAC role assignments for cache storage
3. Optionally delete cache storage account
4. Redeploy previous function version

## 10. Security Considerations

### 10.1 Data Sensitivity

**Cache Data Contains**:
- Resource IDs and names
- Diagnostic setting names
- Resource metadata
- No sensitive customer data

### 10.2 Access Control

- Cache storage isolated from diagnostic logs storage
- RBAC-based access control
- Private endpoint support available
- Automatic data expiration (24 hours)

### 10.3 Compliance

- Data residency follows storage account location
- Supports Azure compliance certifications
- No PII or sensitive data stored in cache
- Automatic cleanup of expired entries

---

**Document Version**: 1.0  
**Last Updated**: 2025-01-29  
**Review Date**: 2025-04-29