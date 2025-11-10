# to redeploy the function with up-to date zip code:

```bash
terraform taint "module.cyngular_function.azurerm_linux_function_app.function_service"
terraform apply --auto-approve
```


<!-- https://learn.microsoft.com/en-us/azure/azure-portal/azure-portal-safelist-urls?tabs=public-cloud -->
