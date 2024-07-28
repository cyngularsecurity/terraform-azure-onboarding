import logging
import traceback
import os

from azure.mgmt.subscription import SubscriptionClient
from azure.identity import ManagedIdentityCredential
# from azure.mgmt.network import NetworkManagementClient
from azure.mgmt.monitor.models import DiagnosticSettingsResource

client_id                = os.environ.get("UAI_ID")

# def handle_exception(func):
#     def wrapper(*args, **kwargs):
#         try:
#             return func(*args, **kwargs)
#         except Exception:
#             logging.critical(traceback.format_exc())
#             return None
#     return wrapper

def get_client_credentials() -> ManagedIdentityCredential:
    try:
        return ManagedIdentityCredential(
            client_id=client_id
        )
    except Exception as e:
        logging.critical(traceback.format_exc())
        raise Exception(f"Error getting cyngular credentials -- {e}")

def get_subscriptions(credentials):
    try:
        subscription_client = SubscriptionClient(credentials)
        sub_list_o = subscription_client.subscriptions.list()

        sub_list = []
        for subscription in sub_list_o:
            sub_list.append({
                'subscription_id': subscription.subscription_id,
                'subscription_name': subscription.display_name
            })
        return sub_list
    except Exception as e:
        raise Exception(f"Error when trying to get subscriptions id list. {e}")

def create_diagnostic_settings(monitor_client, resource_id, resource_name, resource_type, storage_account_id, categories):
    try:
        logs = [{"category": category, "enabled": True} if not is_category_group else {"categoryGroup": category, "enabled": True} for category, is_category_group in categories.items()]

        existing_settings = monitor_client.diagnostic_settings.list(
            resource_uri=resource_id
        )
        setting_name = next((setting.name for setting in existing_settings if setting.storage_account_id == storage_account_id), None)
        operation = "update" if setting_name else "create"

        parameters = DiagnosticSettingsResource(
            storage_account_id=storage_account_id,
            logs=logs
        )

        monitor_client.diagnostic_settings.create_or_update(
            resource_uri=resource_id,
            name=setting_name or "CyngularDiagnostic",
            parameters=parameters
        )

        logging.warning(f"Applied ({operation}) DS on resource -< {resource_name} >- | type -< {resource_type} >-")
    except Exception as e:
        logging.error(f"Failed to Apply ({operation}) DS on resource -< {resource_name} >- | type -< {resource_type} >- : {str(e)}.")


def find_network_watcher(network_client, location):
    network_watchers = network_client.network_watchers.list_all()
    for nw in network_watchers:
        if nw.location.lower() == location.lower():
            return nw
    return None

# # def set_network_watcher(subscription_id, storage_account):
# #     logging.info(f"Configure Network Watcher - Subscription: {subscription_id} - Location: {storage_account['location']}")
# #     print(f"Configure Network Watcher - Subscription: {subscription_id} - Location: {storage_account['location']}")

# #     rg_name = "NetworkWatcherRG"
# #     args = f"""az network watcher list
# #             --query \"[?location=='{storage_account['location']}'].id\"
# #             --subscription {subscription_id}"""

# #     is_network_watcher = azure_cli(args)
# #     if not is_network_watcher:
# #         args = f"""az network watcher configure
# #                 -g {rg_name}
# #                 -l {storage_account['location']}
# #                 --enabled true
# #                 --subscription {subscription_id}"""
# #         azure_cli(args)
# #         time.sleep(30)
# #     else:
# #         logging.info(f"Network watcher already exists for subscription: {subscription_id} and location: {storage_account['location']}")
# #         print(f"Network watcher already exists for subscription: {subscription_id} and location: {storage_account['location']}")

# # @handle_exception
# # def get_nsg_list(subscription_id, storage_account):
# #     logging.info(f"List All NSG in the Specific Location Without Flowlogs - Subscription: {subscription_id} - Location: {storage_account['location']}")
# #     print(f"List All NSG in the Specific Location Without Flowlogs - Subscription: {subscription_id} - Location: {storage_account['location']}")

# #     args = f"""az network watcher flow-log list
# #             --query '[].targetResourceId'
# #             --location {storage_account['location']}
# #             --subscription {subscription_id}"""
# #     nsg_with_flow_logs = azure_cli(args)

# #     args = f"""az network nsg list
# #             --query \"[?location=='{storage_account['location']}'].id\"
# #             --subscription {subscription_id}"""
# #     nsg_list = azure_cli(args)

# #     #Remove all nsg ids that already has nsg flow logs
# #     nsg_without_flow_logs = list(set(nsg_list)-set(nsg_with_flow_logs))
# #     return nsg_without_flow_logs

# # @handle_exception
# # def set_nsg_flow_logs(subscription_id, storage_account, nsg_id):
# #     nsg_name = nsg_id.split('/')[-1]

# #     logging.info(f"Configure NSG Flow Logs - Subscription: {subscription_id} - Location: {storage_account['location']} - NSG Name: {nsg_name}")
# #     print(f"Configure NSG Flow Logs - Subscription: {subscription_id} - Location: {storage_account['location']} - NSG Name: {nsg_name}")

# #     args = f"""az network watcher flow-log create
# #     --location {storage_account['location']}
# #     --name {nsg_name}
# #     --nsg {nsg_id}
# #     --no-wait 1
# #     --storage-account {storage_account['id']}
# #     --subscription {subscription_id}"""
# #     azure_cli(args)

