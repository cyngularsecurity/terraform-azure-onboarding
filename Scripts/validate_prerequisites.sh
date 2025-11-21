#!/bin/bash

#############################################################################
# Terraform Azure Onboarding - Prerequisites Validation Script
#############################################################################
# This script validates all requirements before running Terraform commands
# for the Azure onboarding infrastructure.
#
# Usage:
#   ./Scripts/validate_prerequisites.sh [tfvars_file]
#
# Example:
#   ./Scripts/validate_prerequisites.sh tfvars/client.tfvars
#############################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Function to print colored status messages
print_status() {
    local status=$1
    local message=$2

    case $status in
        "PASS")
            echo -e "${GREEN}✓${NC} ${message}"
            ((PASSED++))
            ;;
        "FAIL")
            echo -e "${RED}✗${NC} ${message}"
            ((FAILED++))
            ;;
        "WARN")
            echo -e "${YELLOW}⚠${NC} ${message}"
            ((WARNINGS++))
            ;;
        "INFO")
            echo -e "${BLUE}ℹ${NC} ${message}"
            ;;
    esac
}

print_section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

#############################################################################
# 1. Check Required CLI Tools
#############################################################################
check_cli_tools() {
    print_section "1. Checking Required CLI Tools"

    # Check Terraform
    if command -v terraform &> /dev/null; then
        TF_VERSION=$(terraform version -json | grep -o '"terraform_version":"[^"]*' | cut -d'"' -f4)
        print_status "PASS" "Terraform CLI installed (version: $TF_VERSION)"

        # Check Terraform version compatibility (>= 1.9.5 recommended)
        REQUIRED_VERSION="1.9.5"
        if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$TF_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
            print_status "PASS" "Terraform version is compatible (>= $REQUIRED_VERSION)"
        else
            print_status "WARN" "Terraform version $TF_VERSION is older than recommended $REQUIRED_VERSION"
        fi
    else
        print_status "FAIL" "Terraform CLI not found. Install from: https://developer.hashicorp.com/terraform/install"
    fi

    # Check Azure CLI
    if command -v az &> /dev/null; then
        AZ_VERSION=$(az version --output tsv 2>/dev/null | grep ^azure-cli | cut -f2)
        print_status "PASS" "Azure CLI installed (version: $AZ_VERSION)"
    else
        print_status "FAIL" "Azure CLI not found. Install from: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli"
    fi

    # Check curl
    if command -v curl &> /dev/null; then
        print_status "PASS" "curl installed"
    else
        print_status "FAIL" "curl not found. Install from: https://developers.greenwayhealth.com/developer-platform/docs/installing-curl"
    fi

    # Check git
    if command -v git &> /dev/null; then
        print_status "PASS" "git installed"
    else
        print_status "FAIL" "git not found. Install from: https://git-scm.com/"
    fi
}

#############################################################################
# 2. Check Azure CLI Authentication
#############################################################################
check_azure_auth() {
    print_section "2. Checking Azure CLI Authentication"

    if ! command -v az &> /dev/null; then
        print_status "FAIL" "Azure CLI not installed, skipping authentication checks"
        return
    fi

    # Check if logged in
    if az account show &> /dev/null; then
        CURRENT_USER=$(az account show --query user.name -o tsv)
        CURRENT_SUB=$(az account show --query name -o tsv)
        CURRENT_SUB_ID=$(az account show --query id -o tsv)
        TENANT_ID=$(az account show --query tenantId -o tsv)

        print_status "PASS" "Authenticated to Azure as: $CURRENT_USER"
        print_status "INFO" "Current subscription: $CURRENT_SUB ($CURRENT_SUB_ID)"
        print_status "INFO" "Tenant ID: $TENANT_ID"
    else
        print_status "FAIL" "Not authenticated to Azure. Run: az login"
    fi
}

#############################################################################
# 3. Check Azure Resource Providers
#############################################################################
check_resource_providers() {
    print_section "3. Checking Azure Resource Providers"

    if ! az account show &> /dev/null; then
        print_status "FAIL" "Not authenticated to Azure, skipping provider checks"
        return
    fi

    # Core required providers
    REQUIRED_PROVIDERS=(
        "Microsoft.Storage"
        "Microsoft.Web"
        "Microsoft.Insights"
        "Microsoft.OperationalInsights"
        "Microsoft.ManagedIdentity"
        "Microsoft.Authorization"
        "Microsoft.Resources"
    )

    # Optional providers (based on enabled features)
    OPTIONAL_PROVIDERS=(
        "Microsoft.Network"
        "Microsoft.ContainerService"
    )

    print_status "INFO" "Checking core required providers..."
    for provider in "${REQUIRED_PROVIDERS[@]}"; do
        STATE=$(az provider show --namespace "$provider" --query "registrationState" -o tsv 2>/dev/null || echo "NotFound")

        if [ "$STATE" = "Registered" ]; then
            print_status "PASS" "$provider is registered"
        elif [ "$STATE" = "Registering" ]; then
            print_status "WARN" "$provider is currently registering (may take a few minutes)"
        else
            print_status "FAIL" "$provider is not registered. Register with: az provider register --namespace $provider"
        fi
    done

    echo ""
    print_status "INFO" "Checking optional providers (for NSG Flow Logs & AKS)..."
    for provider in "${OPTIONAL_PROVIDERS[@]}"; do
        STATE=$(az provider show --namespace "$provider" --query "registrationState" -o tsv 2>/dev/null || echo "NotFound")

        if [ "$STATE" = "Registered" ]; then
            print_status "PASS" "$provider is registered"
        else
            print_status "WARN" "$provider not registered (optional, needed for enable_flow_logs/enable_aks_logs)"
        fi
    done
}

#############################################################################
# 4. Check Management Group Access
#############################################################################
check_management_groups() {
    print_section "4. Checking Management Group Access"

    if ! az account show &> /dev/null; then
        print_status "FAIL" "Not authenticated to Azure, skipping management group checks"
        return
    fi

    TENANT_ID=$(az account show --query tenantId -o tsv)

    # Check if management groups feature is accessible
    if az account management-group show --name "$TENANT_ID" &> /dev/null; then
        print_status "PASS" "Access to root management group confirmed"
        MG_ID=$(az account management-group show --name "$TENANT_ID" --query id -o tsv)
        print_status "INFO" "Root management group ID: $MG_ID"
    else
        print_status "FAIL" "Cannot access root management group. Required permissions:"
        echo "         - Ensure Management Groups feature is enabled"
        echo "         - Elevate access if you are a Global Administrator:"
        echo "           https://learn.microsoft.com/en-us/azure/role-based-access-control/elevate-access-global-admin"
    fi
}

#############################################################################
# 5. Check Required Permissions
#############################################################################
check_permissions() {
    print_section "5. Checking Required Azure Permissions"

    if ! az account show &> /dev/null; then
        print_status "FAIL" "Not authenticated to Azure, skipping permission checks"
        return
    fi

    CURRENT_SUB_ID=$(az account show --query id -o tsv)
    CURRENT_USER_ID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || echo "")

    if [ -z "$CURRENT_USER_ID" ]; then
        print_status "WARN" "Cannot determine current user ID (may be a service principal)"
    else
        print_status "INFO" "Checking permissions for current user..."

        # Check for role assignment write permissions (simplified check)
        ROLE_ASSIGNMENTS=$(az role assignment list --assignee "$CURRENT_USER_ID" --scope "/subscriptions/$CURRENT_SUB_ID" -o json 2>/dev/null || echo "[]")

        if echo "$ROLE_ASSIGNMENTS" | grep -q "Owner\|Contributor"; then
            print_status "PASS" "User has Owner or Contributor role on subscription"
        else
            print_status "WARN" "Could not confirm required permissions. Ensure you have:"
            echo "         - Microsoft.Authorization/roleAssignments/write over management group scope"
            echo "         - Contributor role over subscription(s)"
        fi
    fi
}

#############################################################################
# 6. Check Terraform Configuration
#############################################################################
check_terraform_config() {
    print_section "6. Checking Terraform Configuration"

    # Check if terraform files exist
    if [ -f "main.tf" ]; then
        print_status "PASS" "main.tf found"
    else
        print_status "FAIL" "main.tf not found in current directory"
    fi

    if [ -f "providers.tf" ]; then
        print_status "PASS" "providers.tf found"
    else
        print_status "WARN" "providers.tf not found"
    fi

    if [ -f "vars.tf" ]; then
        print_status "PASS" "vars.tf found"
    else
        print_status "FAIL" "vars.tf not found"
    fi

    # Check for tfvars file if provided as argument
    if [ -n "$1" ]; then
        if [ -f "$1" ]; then
            print_status "PASS" "tfvars file found: $1"

            # Validate required variables in tfvars
            check_required_variables "$1"
        else
            print_status "FAIL" "tfvars file not found: $1"
        fi
    else
        print_status "INFO" "No tfvars file specified for validation"
        if [ -d "tfvars" ]; then
            TFVARS_COUNT=$(find tfvars -name "*.tfvars" | wc -l | tr -d ' ')
            print_status "INFO" "Found $TFVARS_COUNT tfvars file(s) in tfvars/ directory"
        fi
    fi

    # Check for .terraform directory
    if [ -d ".terraform" ]; then
        print_status "PASS" "Terraform initialized (.terraform directory exists)"
    else
        print_status "WARN" "Terraform not initialized. Run: terraform init -upgrade"
    fi
}

#############################################################################
# 7. Validate Required Variables in tfvars
#############################################################################
check_required_variables() {
    local tfvars_file=$1

    echo ""
    print_status "INFO" "Validating required variables in $tfvars_file..."

    # Required variables
    REQUIRED_VARS=("client_name" "main_subscription_id" "application_id" "locations")

    for var in "${REQUIRED_VARS[@]}"; do
        if grep -q "^[[:space:]]*${var}[[:space:]]*=" "$tfvars_file"; then
            VALUE=$(grep "^[[:space:]]*${var}[[:space:]]*=" "$tfvars_file" | head -1)
            print_status "PASS" "Variable '$var' is defined"

            # Validate specific formats
            case $var in
                "client_name")
                    if echo "$VALUE" | grep -qE '[A-Z]'; then
                        print_status "WARN" "client_name should contain only lowercase letters and digits"
                    fi
                    ;;
                "application_id")
                    if ! echo "$VALUE" | grep -qE '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'; then
                        print_status "WARN" "application_id should be a valid UUID"
                    fi
                    ;;
            esac
        else
            print_status "FAIL" "Required variable '$var' not found in $tfvars_file"
        fi
    done
}

#############################################################################
# 8. Quick Registration Script Generator
#############################################################################
generate_registration_script() {
    print_section "8. Resource Provider Registration Helper"

    cat > /tmp/register_azure_providers.sh << 'EOF'
#!/bin/bash
# Auto-generated script to register required Azure Resource Providers

echo "Registering core Azure Resource Providers..."

PROVIDERS=(
    "Microsoft.Storage"
    "Microsoft.Web"
    "Microsoft.Insights"
    "Microsoft.OperationalInsights"
    "Microsoft.ManagedIdentity"
    "Microsoft.Authorization"
    "Microsoft.Resources"
    "Microsoft.Network"
    "Microsoft.ContainerService"
)

for provider in "${PROVIDERS[@]}"; do
    echo "Registering $provider..."
    az provider register --namespace "$provider" --wait
    if [ $? -eq 0 ]; then
        echo "✓ $provider registered successfully"
    else
        echo "✗ Failed to register $provider"
    fi
done

echo ""
echo "Checking registration status..."
for provider in "${PROVIDERS[@]}"; do
    STATE=$(az provider show --namespace "$provider" --query "registrationState" -o tsv)
    echo "$provider: $STATE"
done
EOF

    chmod +x /tmp/register_azure_providers.sh
    print_status "INFO" "Generated registration script: /tmp/register_azure_providers.sh"
    print_status "INFO" "Run it with: bash /tmp/register_azure_providers.sh"
}

#############################################################################
# Summary and Recommendations
#############################################################################
print_summary() {
    print_section "Validation Summary"

    echo ""
    echo -e "${GREEN}Passed: $PASSED${NC}"
    echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
    echo -e "${RED}Failed: $FAILED${NC}"
    echo ""

    if [ $FAILED -eq 0 ]; then
        if [ $WARNINGS -eq 0 ]; then
            print_status "PASS" "All prerequisites validated! You can proceed with Terraform commands."
            echo ""
            echo "Next steps:"
            echo "  1. terraform init -upgrade"
            echo "  2. terraform plan -var-file=\"tfvars/<client>.tfvars\""
            echo "  3. terraform apply -var-file=\"tfvars/<client>.tfvars\" --auto-approve"
        else
            print_status "WARN" "Prerequisites mostly satisfied, but there are warnings to review."
            echo ""
            echo "Review the warnings above, then proceed with:"
            echo "  1. terraform init -upgrade"
            echo "  2. terraform plan -var-file=\"tfvars/<client>.tfvars\""
        fi
    else
        print_status "FAIL" "Some prerequisites failed. Please fix the issues above before proceeding."
        echo ""
        echo "Common fixes:"
        echo "  - Install missing CLI tools"
        echo "  - Run: az login"
        echo "  - Register resource providers: bash /tmp/register_azure_providers.sh"
        echo "  - Elevate access for management groups if needed"
    fi
}

#############################################################################
# Main Execution
#############################################################################
main() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     Azure Terraform Onboarding - Prerequisites Validation           ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    TFVARS_FILE="${1:-}"

    check_cli_tools
    check_azure_auth
    check_resource_providers
    check_management_groups
    check_permissions
    check_terraform_config "$TFVARS_FILE"
    generate_registration_script
    print_summary

    echo ""

    # Exit with error code if there are failures
    if [ $FAILED -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Run main function
main "$@"