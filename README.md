# OnBoarding Workflow

## Prerequisites:
  - cli tools
    - terraform
    - azcli

  - should enable use of management groups for the tenant
  - should have permissions to "Microsoft.Authorization/roleAssignments/write" over scope "/providers/Microsoft.Management/managementGroups/{root mgmt id}"


```
open web browser on the wanted azure environment
return to terminal, type 'az login', and follow the provided instructions
install the terraform.zip file & extract it
open a terminal window on the right path of the terraform configuration files extracted
run 'cp example.tfvars {client_name}.tfvars'
and fill the required values for terraform in the tfvars file
then reurn to terminal and run 'terraform apply --auto-approve --var-file {client_name}.tfvars'
```