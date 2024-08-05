#!/usr/bin/env python

# import os
from azure.identity import DefaultAzureCredential
from azure.mgmt.web import WebSiteManagementClient

def run():
    # Set variables
    subscription_id = os.environ.get('AZURE_SUBSCRIPTION_ID')
    resource_group_name = os.environ.get('RESOURCE_GROUP_NAME')
    function_app_name = os.environ.get('FUNCTION_APP_NAME')

    # Authenticate
    credential = DefaultAzureCredential()
    client = WebSiteManagementClient(credential, subscription_id)

    # Restart the Function App
    client.web_apps.restart(resource_group_name, function_app_name)
    print(f"Function App {function_app_name} restarted successfully.")

if __name__ == "__main__":
    run()
