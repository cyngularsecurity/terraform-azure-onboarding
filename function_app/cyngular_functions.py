import logging
import traceback
import os

from azure.mgmt.subscription import SubscriptionClient
from azure.identity import ManagedIdentityCredential
from azure.mgmt.monitor.models import DiagnosticSettingsResource

client_id                = os.environ.get("UAI_ID")

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