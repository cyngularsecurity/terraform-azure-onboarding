# OnBoarding Workflow

## Prerequisites

* cli tools
  * Terraform cli
  * azcli

* the tenant should have management groups feature enabled
* the applying user should have permissions to "Microsoft.Authorization/roleAssignments/write" over scope "/providers/Microsoft.Management/managementGroups/{root mgmt id}"

create a main.tf file with cyngular module:
add correct values for required parameters:

```hcl
module "onboarding" {
    source  = "cyngularsecurity/onboarding/azure"
    version = "1.0.2"

    application_id = "{application id provided by cyngular}"
    client_name    = "{client name}"
    locations      = ["westus", "westus2"]

  enable_activity_logs            = true
  enable_aks_logs                 = true
  enable_audit_events_logs        = true
  enable_audit_logs               = true
  enable_flow_logs                = true

}
```

For services parameters
provide true, for cyngular to collect logs
If provided false, optionally add tags to storage accounts collecting respective logs:

Entra audit logs - {key: cyngular-auditlogs, value: true}
Subscriptions diagnostic settings - {key: cyngular-activitylogs, value: true}
Resource diagnostic settings - {key: cyngular-auditevents, value: true}
Nsgs flow logs - {key: cyngular-nsgflowlogs, value: true}
AKS Cluster diagnostic settings - {key: cyngular-aks, value: true}

* open web browser on the wanted azure environment.
* return to terminal, Authenticate with your Azure account

```bash
az login # and follow the provided instructions
```

(for more info visit - <https://registry.terraform.io/modules/cyngularsecurity/onboarding/azure/latest>)

run:

```bash
terraform init
terraform plan
terraform apply --auto-approve
```
