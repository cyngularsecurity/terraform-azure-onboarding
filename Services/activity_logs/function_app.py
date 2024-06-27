import logging

import azure.functions as func

from azure.identity import DefaultAzureCredential, ManagedIdentityCredential
from azure.mgmt.monitor import MonitorManagementClient
from azure.mgmt.monitor.models import DiagnosticSettingsResource


credential = ManagedIdentityCredential()

credential = ManagedIdentityCredential(
    client_id="54d51bb3-d5a5-4142-a754-a6b8055d5824",
)

app = func.FunctionApp()
# credential = DefaultAzureCredential()
monitor_client = MonitorManagementClient(credential, "373cb248-9e3b-4f65-8174-c72d253103ea")

ALL_AND_AUDIT_LOG_SETTINGS = [
    {
        "categoryGroup": "audit",
        "enabled": True,
        "retentionPolicy": {
            "enabled": False,
            "days": 30
        }
    },
    {
        "categoryGroup": "allLogs",
        "enabled": True,
        "retentionPolicy": {
            "enabled": False,
            "days": 30
        }
    }
]

def create_diagnostic_settings(vm_resource_id, storage_account_id):
    try:
        settings = DiagnosticSettingsResource(
            storage_account_id=storage_account_id,
            logs=ALL_AND_AUDIT_LOG_SETTINGS
        )

        monitor_client.diagnostic_settings.create_or_update(
            resource_uri=vm_resource_id,
            parameters=settings,
            name="CyngularDiagnostic"
        )

        logging.warning('Diagnostic settings applied successfully.')
    except Exception as e:
        logging.warning(f"Failed to apply diagnostic settings: {str(e)}.")


@app.function_name(name="DS")
@app.route(route="hello", auth_level=func.AuthLevel.ANONYMOUS)
def test_function(req: func.HttpRequest) -> func.HttpResponse:
    
    vm_resource_id = "/subscriptions/373cb248-9e3b-4f65-8174-c72d253103ea/resourceGroups/stark-rg/providers/Microsoft.KeyVault/vaults/stark-keyvault"
    storage_account_id = "/subscriptions/373cb248-9e3b-4f65-8174-c72d253103ea/resourceGroups/cyngular-tesla-rg/providers/Microsoft.Storage/storageAccounts/cyngularteslawestus"

    create_diagnostic_settings(vm_resource_id, storage_account_id)

    logging.warning('Python HTTP trigger function processed a request.')
    return func.HttpResponse(
        "This HTTP triggered function executed successfully.",
        status_code=200
        )