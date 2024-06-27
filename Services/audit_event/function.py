
import logging
import os
import json
import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.mgmt.resourcegraph import ResourceGraphClient
from azure.mgmt.monitor import MonitorManagementClient
from azure.mgmt.monitor.models import DiagnosticSettingsResource

# Initialize clients
credential = DefaultAzureCredential()
resource_graph_client = ResourceGraphClient(credential)
monitor_client = MonitorManagementClient(credential, os.environ['AZURE_SUBSCRIPTION_ID'])

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    # Query Resource Graph
    query = "Resources | where type == 'microsoft.compute/virtualmachines'"
    response = resource_graph_client.resources(query=query, subscriptions=[os.environ['AZURE_SUBSCRIPTION_ID']])
    resources = response.data

    for resource in resources:
        resource_id = resource['id']
        # Check if diagnostic settings are configured
        diagnostic_settings = monitor_client.diagnostic_settings.list(resource_id)
        if not any(diagnostic_settings):
            # Deploy diagnostic settings
            deploy_diagnostic_settings(resource_id)

    return func.HttpResponse("Diagnostic settings deployment completed.", status_code=200)

def deploy_diagnostic_settings(resource_id):
    diagnostic_settings_params = DiagnosticSettingsResource(
        storage_account_id=os.environ['STORAGE_ACCOUNT_ID'],
        logs=[
            {
                "category": "Administrative",
                "enabled": True,
                "retentionPolicy": {
                    "enabled": False,
                    "days": 0
                }
            },
            {
                "category": "Security",
                "enabled": True,
                "retentionPolicy": {
                    "enabled": False,
                    "days": 0
                }
            }
        ]
    )
    monitor_client.diagnostic_settings.create_or_update(
        resource_id,
        'myDiagnosticSetting',
        diagnostic_settings_params
    )
