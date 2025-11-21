# Scripts Directory

This directory contains utility scripts for the Azure Terraform onboarding infrastructure.

## validate_prerequisites.sh

Comprehensive validation script that checks all prerequisites before running Terraform commands.

### What It Checks

1. **CLI Tools**
   - Terraform CLI (version 1.9.5+ recommended)
   - Azure CLI
   - curl
   - git

2. **Azure Authentication**
   - Azure CLI login status
   - Current subscription and tenant
   - User identity

3. **Azure Resource Providers**
   - Core required providers:
     - Microsoft.Storage
     - Microsoft.Web
     - Microsoft.Insights
     - Microsoft.OperationalInsights
     - Microsoft.ManagedIdentity
     - Microsoft.Authorization
     - Microsoft.Resources
   - Optional providers (for specific features):
     - Microsoft.Network (NSG Flow Logs)
     - Microsoft.ContainerService (AKS Logs)

4. **Management Group Access**
   - Access to root management group
   - Management Groups feature enabled

5. **Azure Permissions**
   - Role assignments on subscriptions
   - Required permissions for resource deployment

6. **Terraform Configuration**
   - Presence of required .tf files
   - Terraform initialization status
   - tfvars file validation (if provided)

7. **Variable Validation**
   - Required variables: client_name, main_subscription_id, application_id, locations
   - Format validation for client_name (lowercase alphanumeric)
   - Format validation for application_id (UUID)

### Usage

#### Basic validation (from repository root):
```bash
./Scripts/validate_prerequisites.sh
```

#### Validate with specific tfvars file:
```bash
./Scripts/validate_prerequisites.sh tfvars/client.tfvars
```

### Output

The script provides:
- ✓ Green checkmarks for passed validations
- ⚠ Yellow warnings for non-critical issues
- ✗ Red crosses for failed validations
- ℹ Blue info messages for informational output

### Exit Codes

- `0`: All validations passed (may have warnings)
- `1`: One or more validations failed

### Auto-Generated Registration Script

The validation script automatically generates a helper script at `/tmp/register_azure_providers.sh` that you can run to register all required Azure Resource Providers:

```bash
bash /tmp/register_azure_providers.sh
```

This script registers providers with the `--wait` flag to ensure registration completes before proceeding.

### Example Output

```
╔══════════════════════════════════════════════════════════════════════╗
║     Azure Terraform Onboarding - Prerequisites Validation           ║
╚══════════════════════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1. Checking Required CLI Tools
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Terraform CLI installed (version: 1.9.5)
✓ Terraform version is compatible (>= 1.9.5)
✓ Azure CLI installed (version: 2.64.0)
✓ curl installed
✓ git installed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  2. Checking Azure CLI Authentication
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Authenticated to Azure as: user@company.com
ℹ Current subscription: Production (c14256c0-36d2-40e4-878c-d7c2e34486de)
...
```

### Recommended Workflow

1. **Before any Terraform operations**, run the validation script:
   ```bash
   ./Scripts/validate_prerequisites.sh tfvars/yourclient.tfvars
   ```

2. **Fix any issues** identified by the script

3. **If resource providers are not registered**, run the generated script:
   ```bash
   bash /tmp/register_azure_providers.sh
   ```

4. **Re-run validation** to confirm all checks pass:
   ```bash
   ./Scripts/validate_prerequisites.sh tfvars/yourclient.tfvars
   ```

5. **Proceed with Terraform**:
   ```bash
   terraform init -upgrade
   terraform plan -var-file="tfvars/yourclient.tfvars"
   terraform apply -var-file="tfvars/yourclient.tfvars" --auto-approve
   ```

### Integration with CI/CD

You can integrate this script into your CI/CD pipelines to validate prerequisites before automated deployments:

```bash
# In your CI/CD pipeline
./Scripts/validate_prerequisites.sh tfvars/${CLIENT_NAME}.tfvars
if [ $? -ne 0 ]; then
    echo "Prerequisites validation failed"
    exit 1
fi

# Proceed with terraform commands
terraform init -upgrade
terraform plan -var-file="tfvars/${CLIENT_NAME}.tfvars"
```

### Troubleshooting

**Script fails with permission denied:**
```bash
chmod +x Scripts/validate_prerequisites.sh
```

**Azure CLI not authenticated:**
```bash
az login
az account set --subscription <subscription-id>
```

**Resource providers not registered:**
```bash
bash /tmp/register_azure_providers.sh
```

**Management group access denied:**
- Ensure you have Global Administrator role or equivalent
- Follow the elevation guide: https://learn.microsoft.com/en-us/azure/role-based-access-control/elevate-access-global-admin