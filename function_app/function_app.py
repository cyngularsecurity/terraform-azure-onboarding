import logging
import traceback
import os
import json

import diagnostic_settings as cyngular_ds
import cyngular_functions as cyngular_func

import azure.functions as func
import azure.durable_functions as df
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.resourcegraph import ResourceGraphClient
from azure.mgmt.resourcegraph.models import QueryRequest, QueryRequestOptions, ResultFormat
from azure.mgmt.network import NetworkManagementClient
from azure.mgmt.monitor import MonitorManagementClient
from azure.mgmt.monitor.models import DiagnosticSettingsResource

try:
    storage_account_mappings = json.loads(os.environ['STORAGE_ACCOUNT_MAPPINGS'])
    company_locations        = json.loads(os.environ['COMPANY_LOCATIONS'])
    tenant_id                = os.environ['ROOT_MGMT_GROUP_ID']

    enable_activity_logs = os.environ.get('enable_activity_logs', 'false').lower() == 'true'
    enable_audit_events_logs = os.environ.get('enable_audit_events_logs', 'false').lower() == 'true'
    enable_aks_logs = os.environ.get('enable_aks_logs', 'false').lower() == 'true'

    enable_flow_logs = os.environ.get('enable_flow_logs', 'false').lower() == 'true'
except Exception as e:
    logging.critical(f"Error parsing environment variables: {e}")
    raise

logging.basicConfig(
    filename="onboarding.log", filemode="a", level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

credential = cyngular_func.get_client_credentials()
primary_location = company_locations[0].strip()
cyngular_ds_name = "CyngularDiagnostic"

# """
# cyngulat trigger for Orchestration --  Durable Client Function
# """
OnBoard = df.DFApp(func.AuthLevel.ANONYMOUS)
# @OnBoard.route(route="DS/")
# @OnBoard.durable_client_input(client_name="client")
# async def durable_trigger_function_ds(req: func.HttpRequest, client):
@OnBoard.durable_client_input(client_name="client")
@OnBoard.schedule(schedule="0 * * * *", arg_name="DailyTimer", run_on_startup=True)
async def durable_trigger_function_ds(DailyTimer: func.TimerRequest, client):
    logging.warning("-- started client durable func --")
    instance_id = await client.start_new("main_orchestrator")
    logging.warning(f"Started orchestration with ID = '{instance_id}'.")

    # response = client.create_check_status_response(req, instance_id)
    # return response

# """
# cyngular trigger for services --  Orchestration Function
# """
@OnBoard.orchestration_trigger(context_name="context")
def main_orchestrator(context: df.DurableOrchestrationContext):
    try:
        logging.warning(f"-- Started main orhcestrator func --")
        subscriptions = cyngular_func.get_subscriptions(credential)

        sub_tasks = [context.call_sub_orchestrator("sub_orchestrator", sub) for  sub in subscriptions]

        results = yield context.task_all(sub_tasks)
        logging.warning(f"Completed orchestration with results: {results}")
    except Exception:
        logging.critical(traceback.format_exc())
        return "An error occurred during the orchestration."

@OnBoard.orchestration_trigger(context_name="context")
def sub_orchestrator(context: df.DurableOrchestrationContext):
    subscription_data = context.get_input()
    subscription_id = subscription_data['subscription_id']
    subscription_name = subscription_data['subscription_name']
    try:
        logging.warning(f"-- started sub orchestrator func subscription -< {subscription_name} >-")
        locations = company_locations
        if primary_location not in storage_account_mappings:
            raise ValueError(f"Primary location '{primary_location}' not found in storage account mappings.")
        logging.warning(f"-- primary location -< {primary_location} >-")

        resources = yield context.call_activity("query_resources", {
            "subscription_id": subscription_id,
            "locations": locations,
            "blacklisted_types": cyngular_ds.blacklisted_types
        })

        audit_event_tasks, nsg_tasks = [], []
        audit_event_tasks.append(context.call_activity("set_audit_event_ds", {
            "subscription_id": subscription_id,
            "resources": resources,
        }))

        for location in locations:
            nsg_tasks.append(context.call_activity("set_nsg_flow_logs", {
                "subscription_id": subscription_id,
                "location": location
            }))

        if enable_activity_logs:
            yield context.call_activity("set_activity_logs_ds", {
                "subscription_id": subscription_id,
                "subscription_name": subscription_name,
                "storage_account_id": storage_account_mappings[primary_location]
            })

        results = yield context.task_all(audit_event_tasks + nsg_tasks)
        logging.warning(f"results: {results}")

        logging.warning(f"Completed Orchestration for sub -< {subscription_name} >-.")
        return "Orchestration sub completed successfully."
    except Exception:
        logging.critical(traceback.format_exc())
        return "An error occurred during the sub orchestration."

# """
# cyngular services --  Activity Functions
# """
@OnBoard.activity_trigger(input_name="input")
def query_resources(input):
    subscription_id   = input["subscription_id"]
    locations         = input["locations"]
    blacklisted_types = input["blacklisted_types"]

    try:
        resource_graph_client = ResourceGraphClient(credential)
        blacklist = ", ".join(f"'{rt.lower()}'" for rt in blacklisted_types)
        locations = ", ".join(f"'{loc}'" for loc in locations)

        query = f"""
        resources
        | where type !in ({blacklist})
        | where location in ({locations})
        | project id, name, type, location, resourceGroup
        """

        logging.warning(f"sub id for query: -< {subscription_id} >-")
        options = QueryRequestOptions(result_format=ResultFormat.object_array)
        request = QueryRequest(
            query=query,
            subscriptions=[subscription_id],
            options=options
        )
        response = resource_graph_client.resources(request)

        if response.count == 0:
            logging.error(f"No resources found in subscription: {subscription_id}") 
            return []
        else:
            logging.warning(f"Total resources found: {response.count} -- in subscription: {subscription_id}")
            return response.data

    except Exception:
        logging.critical(traceback.format_exc())
        return []

@OnBoard.activity_trigger(input_name="input")
def set_activity_logs_ds(input):
    subscription_id = input["subscription_id"]
    subscription_name = input["subscription_name"]
    storage_account_id = input["storage_account_id"]

    try:
        monitor_client = MonitorManagementClient(credential, subscription_id)
        existing_settings = monitor_client.diagnostic_settings.list(
            resource_uri=f"/subscriptions/{subscription_id}"
        )
        # generator expression, find first ds matching the given storage_account_id. If none are found, defaults to None.
        setting_name = next(
            (setting.name for setting in existing_settings if setting.storage_account_id == storage_account_id),
            None
        )
        operation = "update" if setting_name else "create"

        parameters = DiagnosticSettingsResource(
            storage_account_id=storage_account_id,
            logs=[{"category": category, "enabled": True} for category in cyngular_ds.ACTIVITY_LOG_SETTINGS]
        )

        monitor_client.diagnostic_settings.create_or_update(
            resource_uri=f"/subscriptions/{subscription_id}",
            name=setting_name or cyngular_ds_name,
            parameters=parameters
        )
        logging.warning(f"Activity Logs deployed -< {operation.capitalize()} >- for sub: {subscription_id} ({subscription_name})")
    except Exception:
        logging.critical(traceback.format_exc())
        return {"status": "failed"}
    return {"status": "success"}

@OnBoard.activity_trigger(input_name="input")
def set_audit_event_ds(input):
    subscription_id = input["subscription_id"]
    resources = input["resources"]

    try:
        monitor_client = MonitorManagementClient(credential, subscription_id)
        all_logs_types = [rtype.lower() for rtype in cyngular_ds.all_logs_types]
        all_logs_and_audit_types = [rtype.lower() for rtype in cyngular_ds.all_logs_and_audit_types]

        for resource in resources:
            resource_name = resource['name']
            resource_id = resource['id']
            resource_type = resource['type'].lower()
            location = resource['location']
            storage_account_id = storage_account_mappings[location]
            categories = {}

            if enable_aks_logs and resource_type == 'microsoft.containerservice/managedclusters':
                categories.update(cyngular_ds.AKS_SETTINGS)

            if enable_audit_events_logs:
                if resource_type in all_logs_types:
                    categories.update(cyngular_ds.ALL_LOGS_SETTING)
                elif resource_type in all_logs_and_audit_types:
                    categories.update(cyngular_ds.ALL_AND_AUDIT_LOG_SETTINGS)
                elif not categories:
                    categories.update(cyngular_ds.AUDIT_EVENT_LOG_SETTINGS)
                        
            if categories:
                diagnostic_settings = monitor_client.diagnostic_settings.list(resource_id)
                if not any(ds for ds in diagnostic_settings if all(
                    log.category in categories and log.enabled for log in ds.logs
                )):
                    cyngular_func.create_diagnostic_settings(monitor_client, resource_id, resource_name, resource_type, storage_account_id, categories)
        logging.warning(f"Checked and updated diagnostic settings for sub: {subscription_id}")
    except Exception:
        logging.critical(traceback.format_exc())
        return {"status": "failed"}
    return {"status": "success"}

@OnBoard.activity_trigger(input_name="input")
def set_nsg_flow_logs(input):
    subscription_id = input["subscription_id"]
    location = input["location"]
    storage_account_id = storage_account_mappings[location]

    try:
        logging.warning(f"Started NSG Flow Logs for sub: {subscription_id} | Location: {location}")
        network_client = NetworkManagementClient(credential, subscription_id)
        resource_client = ResourceManagementClient(credential, subscription_id)

        network_watcher = cyngular_func.find_network_watcher(network_client, location)

        if not network_watcher:
            rg_name = "NetworkWatcherRG"
            nw_name = f"NetworkWatcher_{location}"
            
            try:
                resource_client.resource_groups.get(rg_name)
            except Exception:
                resource_client.resource_groups.create_or_update(rg_name, {"location": location})
                logging.warning(f"Created Resource Group: {rg_name} in location: {location}")

            network_watcher = network_client.network_watchers.create_or_update(
                resource_group_name=rg_name,
                network_watcher_name=nw_name,
                parameters={"location": location}
            )
            logging.warning(f"Created Network Watcher in location: {location} | for sub {subscription_id}")
        else:
            logging.warning(f"Using existing Network Watcher: {network_watcher.name} in resource group: {network_watcher.id.split('/')[4]}")

        nsgs = network_client.network_security_groups.list_all()
        for nsg in nsgs:
            if nsg.location == location:
                logging.warning(f"Checking flow logs on NSG: {nsg.name}")
                nsg_rg_name = nsg.id.split("/")[4]
                nsg_flow_log_name = f"{nsg.name}-FlowLog" # "NetworkWatcherFlowLog"

                try:
                    flow_log_settings = network_client.flow_logs.get(
                        resource_group_name=network_watcher.id.split('/')[4],
                        # network_security_group_name=nsg.name,
                        network_watcher_name=network_watcher.name,
                        flow_log_name=nsg_flow_log_name
                    )
                except Exception:
                    flow_log_settings = None

                if not flow_log_settings or flow_log_settings.storage_id != storage_account_id:
                    poller = network_client.flow_logs.begin_create_or_update(
                        resource_group_name=network_watcher.id.split('/')[4],
                        network_watcher_name=network_watcher.name,
                        flow_log_name=nsg_flow_log_name,
                        parameters={
                            "enabled": True,
                            "location": location,
                            "targetResourceId": nsg.id,
                            "storageId": storage_account_id,
                            "retentionPolicy": {
                                "days": 0,
                                "enabled": False
                            },
                            "format": {
                                "type": "JSON",
                                "version": 2
                            }
                        }
                    )
                    result = poller.result()
                    logging.warning(f"Updated/Created flow log version 2 for NSG: {nsg.name} in location: {location}")
                    logging.warning(f"nsg begin create -- res: {result}")

        logging.warning(f"NSG flow logs checked and updated for subscription: {subscription_id} | Location: {location}")
    except Exception as e:
        logging.critical(f"Failed to set NSG flow logs for subscription: {subscription_id} | Location: {location}. Error: {str(e)}")
        return {"status": "failed"}
    return {"status": "success"}

# <!-- 
#     try:
#         logging.warning(f"Started NSG Flow Logs for sub: {subscription_id} | Location: {location}")
#         network_client = NetworkManagementClient(credential, subscription_id)
#         resource_client = ResourceManagementClient(credential, subscription_id)

#         nw_list = network_client.network_watchers.list_all()
#         nw_locations = [nw.location for nw in nw_list]

#         if location not in nw_locations: -->

