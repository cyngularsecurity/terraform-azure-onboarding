import logging
import traceback
import time
import os
import json
# import subprocess
# import shlex

import diagnostic_settings as ds
from azure.identity import ClientSecretCredential, ManagedIdentityCredential

from azure.mgmt.monitor.models import DiagnosticSettingsResource
from azure.mgmt.monitor import MonitorManagementClient
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.network import NetworkManagementClient

from azure.mgmt.resourcegraph import ResourceGraphClient
from azure.mgmt.managementgroups import ManagementGroupsAPI

credential = ManagedIdentityCredential(
    client_id="54d51bb3-d5a5-4142-a754-a6b8055d5824",
)

resource_graph_client = ResourceGraphClient(credential)
management_groups_client = ManagementGroupsAPI(credential)


logging.basicConfig(
    filename="onboarding.log",
    filemode="a",
    format="%(asctime)s - %(levelname)s - %(message)s",
    level=logging.INFO,
)

# monitor_client = MonitorManagementClient(credential, "373cb248-9e3b-4f65-8174-c72d253103ea")
monitor_client = MonitorManagementClient(credential, os.environ['AZURE_SUBSCRIPTION_ID'])

def handle_exception(func):
    def wrapper(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except Exception:
            logging.critical(traceback.format_exc())
    return wrapper


def create_diagnostic_settings(vm_resource_id, storage_account_id):
    try:
        # if any(r in resource_id for r in ["storageAccounts", "virtualMachines", "networkInterfaces", "disks", "virtualNetworks", "sshPublicKeys", "serverFarms", "sites", "networkwatchers", "snapshots"]):
        #     return
        # if ("Microsoft.Sql" in resource_id or "flexibleServers" in resource_id or "publicIPAddresses" in resource_id or "vaults" in resource_id or "namespaces" in resource_id or "workspaces" in resource_id):
        # elif ("networkSecurityGroups" in resource_id or "bastionHosts" in resource_id or "components" in resource_id):

        settings = DiagnosticSettingsResource(
            storage_account_id=storage_account_id,
            logs=ds.ALL_AND_AUDIT_LOG_SETTINGS
        )

        monitor_client.diagnostic_settings.create_or_update(
            resource_uri=vm_resource_id,
            parameters=settings,
            name="CyngularDiagnostic"
        )

        logging.warning('Diagnostic settings applied successfully.')
    except Exception as e:
        logging.warning(f"Failed to apply diagnostic settings: {str(e)}.")


def set_network_watcher(subscription_id, storage_account):
    logging.info(f"Configure Network Watcher - Subscription: {subscription_id} - Location: {storage_account['location']}")
    print(f"Configure Network Watcher - Subscription: {subscription_id} - Location: {storage_account['location']}")

    rg_name = "NetworkWatcherRG"
    args = f"""az network watcher list
            --query \"[?location=='{storage_account['location']}'].id\"
            --subscription {subscription_id}"""

    is_network_watcher = azure_cli(args)
    if not is_network_watcher:
        args = f"""az network watcher configure
                -g {rg_name}
                -l {storage_account['location']}
                --enabled true
                --subscription {subscription_id}"""
        azure_cli(args)
        time.sleep(30)
    else:
        logging.info(f"Network watcher already exists for subscription: {subscription_id} and location: {storage_account['location']}")
        print(f"Network watcher already exists for subscription: {subscription_id} and location: {storage_account['location']}")

@handle_exception
def get_nsg_list(subscription_id, storage_account):
    logging.info(f"List All NSG in the Specific Location Without Flowlogs - Subscription: {subscription_id} - Location: {storage_account['location']}")
    print(f"List All NSG in the Specific Location Without Flowlogs - Subscription: {subscription_id} - Location: {storage_account['location']}")

    args = f"""az network watcher flow-log list
            --query '[].targetResourceId'
            --location {storage_account['location']}
            --subscription {subscription_id}"""
    nsg_with_flow_logs = azure_cli(args)

    args = f"""az network nsg list
            --query \"[?location=='{storage_account['location']}'].id\"
            --subscription {subscription_id}"""
    nsg_list = azure_cli(args)

    #Remove all nsg ids that already has nsg flow logs
    nsg_without_flow_logs = list(set(nsg_list)-set(nsg_with_flow_logs))
    return nsg_without_flow_logs

@handle_exception
def set_nsg_flow_logs(subscription_id, storage_account, nsg_id):
    nsg_name = nsg_id.split('/')[-1]

    logging.info(f"Configure NSG Flow Logs - Subscription: {subscription_id} - Location: {storage_account['location']} - NSG Name: {nsg_name}")
    print(f"Configure NSG Flow Logs - Subscription: {subscription_id} - Location: {storage_account['location']} - NSG Name: {nsg_name}")

    args = f"""az network watcher flow-log create
    --location {storage_account['location']}
    --name {nsg_name}
    --nsg {nsg_id}
    --no-wait 1
    --storage-account {storage_account['id']}
    --subscription {subscription_id}"""
    azure_cli(args)
