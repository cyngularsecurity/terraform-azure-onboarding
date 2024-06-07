import json
import logging
import traceback
import azure_functions
from concurrent.futures import ThreadPoolExecutor, wait
import os

# Authenticate with Azure
azure_functions.azure_login()
azure_functions.add_account_extension()

# Load configuration from file
with open('client_config.json', 'r') as file:
    client_config = json.load(file)

# Load configuration from file
with open('cyngular_config.json', 'r') as file:
    cyngular_config = json.load(file)

azure_functions.validate_client_config_file(client_config)
azure_functions.validate_cyngular_config_file(cyngular_config)

workers = cyngular_config['maxWorkers'] # Number of workers
sp_object_id = cyngular_config['servicePrincipalID'] # Service principal id
data_sources = cyngular_config['dataSources']  # Data sources
storage_accounts = client_config['storageAccounts']  # Storage account information
sp_permissions = cyngular_config['spPermissions']  # Service principal permissions
cyngular_app_id = cyngular_config['cyngularAppId']  # Service principal permissions
activity_file = cyngular_config['activityFile']  # Activity file location

# Assuming the first storage account is the target for certain logs
main_storage_account = storage_accounts[0]
subscription_ids = azure_functions.get_subscriptions_list()

# 1. Create a Service Principal
if 'Service Principal' in data_sources:
    if not sp_object_id:
        sp_object_id = azure_functions.create_sp(cyngular_app_id)

# 2. Configure permissions to a service principal across all subscriptions
if 'Subscriptions Permission' in data_sources:
    with ThreadPoolExecutor(max_workers=workers) as executor:
        for subscription_id in subscription_ids:
            executor.submit(azure_functions.set_sp_permissions, subscription_id, sp_object_id, sp_permissions)

# 3. Configure Activity Logs for each subscription
if 'Activity Logs' in data_sources:
    with ThreadPoolExecutor(max_workers=workers) as executor:
        for subscription_id in subscription_ids:
            executor.submit(azure_functions.set_subscription_activity_logs, subscription_id, main_storage_account, activity_file)

# 4. Configure Resources Activity Logs based on location
if 'Audit Events' in data_sources:
    with ThreadPoolExecutor(max_workers=workers) as executor:
        for subscription_id in subscription_ids:
            for storage_account in storage_accounts:
                resource_ids = azure_functions.get_resources_by_loaction(subscription_id, storage_account)
                for resource_id in resource_ids:
                    executor.submit(azure_functions.set_resource_activity_logs, subscription_id, storage_account, resource_id)

# 5. Configure Network Watcher based on location
if 'NSG Flow Logs' in data_sources:
    with ThreadPoolExecutor(max_workers=workers) as executor:
        for subscription_id in subscription_ids:
            futures = [
                executor.submit(azure_functions.set_network_watcher, subscription_id, storage_account)
                for storage_account in storage_accounts
            ]
            wait(futures)

        for subscription_id in subscription_ids:
            for storage_account in storage_accounts:
                nsg_without_flow_logs = azure_functions.get_nsg_list(subscription_id, storage_account)
                for nsg_id in nsg_without_flow_logs:
                    executor.submit(azure_functions.set_nsg_flow_logs, subscription_id, storage_account, nsg_id)
