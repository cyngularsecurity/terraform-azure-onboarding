## Important Notices

### Terraform Version Requirements
- Terraform CLI version `1.9.5` or compatible as specified in release `3.3`
- Azure CLI is required for authentication

### Resource Limits
- **Diagnostic Settings Limit**: Maximum of 5 diagnostic settings per subscription. Ensure you do not exceed this limit when enabling log collection.

### State Management (Non-Remote Backend)
If not using a remote Terraform backend, save your Terraform state for future management:

```bash
# Save state
terraform state pull > cyngular_onboarding.tfstate

# Restore state
terraform state push cyngular_onboarding.tfstate
```
