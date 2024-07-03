
@OnBoard.orchestration_trigger(context_name="context")
def aks_orchestrator_function(context: df.DurableOrchestrationContext):
    try:
        root_management_group_id = context.get_input()
        locations = company_locations
        resource_types = ["Microsoft.ContainerService/managedClusters"]
        categories = ["category1", "category2"]  # Define your categories
        nsg_categories = ["category3"]  # Define NSG categories

        logging.warning("-- started orchestrator function --")
        logging.warning(f"-- 1. root_management_group_id -- {root_management_group_id}")
        logging.warning(f"-- 2. locations -- {locations}")

        all_subscriptions = []
        mg_queue = [root_management_group_id]
        while mg_queue:
            current_mg_id = mg_queue.pop(0)
            logging.warning(f"-- Processing management group -- {current_mg_id}")

            # Get subscriptions and child management groups
            result = yield context.call_activity("mgmt_group_subs", current_mg_id)
            mg_queue.extend(result["managementGroups"])
            all_subscriptions.extend(result["subscriptions"])

        logging.warning(f"-- 3. all_subscriptions -- {all_subscriptions}")

        # Iterate over all subscriptions
        for subscription_id in all_subscriptions:
            # Query resources and check & deploy diagnostic settings
            resources = yield context.call_activity("query_resources", {
                "subscription_id": subscription_id,
                "locations": locations,
                "resource_types": resource_types
            })

            # Check and deploy diagnostic settings for resources
            for resource in resources:
                yield context.call_activity("check_and_deploy_diagnostic_settings", {
                    "subscription_id": subscription_id,
                    "resources": [resource],  # single resource
                    "categories": categories
                })

            # Check and deploy NSG flow logs
            for location in locations:
                yield context.call_activity("check_and_deploy_nsg_flow_logs", {
                    "subscription_id": subscription_id,
                    "location": location
                })

            # Deploy static diagnostic settings on subscription
            yield context.call_activity("deploy_static_diagnostic_settings", {
                "subscription_id": subscription_id,
                "settings": [
                    {
                        "name": "SubscriptionDiagnosticSettings",
                        "storage_account_id": storage_account_mappings[locations[0]],  # assuming first location's storage
                        "logs": [{"category": cat, "enabled": True} for cat in categories]
                    }
                ]
            })

        logging.info("Completed orchestration.")
        return "Orchestration completed successfully."
    except Exception:
        logging.critical(traceback.format_exc())
        return "An error occurred during the orchestration."

# @OnBoard.orchestration_trigger(context_name="context")
# def aks_orchestrator_function(context: df.DurableOrchestrationContext):
#     try:
#         root_management_group_id = context.get_input()
#         locations = company_locations
#         resource_types = ["Microsoft.ContainerService/managedClusters"]
#         logging.warning("-- started orchestrator function --")
#         logging.warning(f"-- 1. root_management_group_id -- {root_management_group_id}")
#         logging.warning(f"-- 2. locations -- {locations}")

#         all_subscriptions = []
#         mg_queue = [root_management_group_id]

#         while mg_queue:
#             current_mg_id = mg_queue.pop(0)
#             logging.warning(f"-- Processing management group -- {current_mg_id}")

#             # Get subscriptions and child management groups
#             result = yield context.call_activity("mgmt_group_subs", current_mg_id)
#             mg_queue.extend(result["managementGroups"])
#             all_subscriptions.extend(result["subscriptions"])

#         logging.warning(f"-- 3. all_subscriptions -- {all_subscriptions}")


#         return "Orchestration completed successfully."
#     except Exception:
#         logging.critical(traceback.format_exc())
#         return "An error occurred during the orchestration."

# """
# cyngulat trigger for services --  Orchestration Function
# """
@OnBoard.orchestration_trigger(context_name="context")
def aks_orchestrator_function(context: df.DurableOrchestrationContext):
    try:
        # root_management_group_id = os.environ['ROOT_MGMT_GROUP']
        root_management_group_id = context.get_input()
        locations = company_locations # ["eastus", "westus"]
        resource_types = ["Microsoft.ContainerService/managedClusters"]
        logging.warning("-- started orchestrator func --")
        logging.warning(f"-- 1. root_management_group_id -- {root_management_group_id}")
        logging.warning(f"-- 2. locations -- {locations}")

        # all_subscriptions = []
        # # Queue for management groups to process
        # mg_queue = [tenant_id]

        # while mg_queue:
        #     current_mg_id = mg_queue.pop(0)
        #     logging.warning(f"-- Processing management group -- {current_mg_id}")

        #     # Get subscriptions and child management groups
        #     result = yield context.call_activity("mgmt_group_subs", current_mg_id)
        #     mg_queue.extend(result["managementGroups"])
        #     all_subscriptions.extend(result["subscriptions"])

        # service_usage_enabled = yield context.call_activity("check_and_enable_mgmt_group_service_usage", root_management_group_id)
        # if not service_usage_enabled:
        #     return "Failed to enable management group service usage."


        # # Flatten list of resources
        # resources = [item for sublist in resources for item in sublist]
        # logging.warning(f"-- 5. Flatten resources -- {resources}")

        # # Fan-out to check and deploy diagnostic settings in parallel
        # tasks = [
        #     context.call_activity("check_and_deploy_diagnostic_settings", resource['id'], storage_account_mappings.get(resource['location']))
        #     for resource in resources if storage_account_mappings.get(resource['location'])
        # ]

        # yield context.task_all(tasks)
        # logging.warning("-- 6. Diagnostic settings deployment completed --")
        # return "Diagnostic settings deployment completed."
    except Exception:
        logging.critical(traceback.format_exc())
        return "An error occurred during the orchestration."
    # return 0

# @OnBoard.activity_trigger(input_name="input")
# def check_and_enable_mgmt_group_service_usage(root_management_group_id):
#     try:
#         # Check if the management group service usage is enabled
#         mgmt_group = management_groups_client.management_groups.get(root_management_group_id)
#         if not mgmt_group.properties.details.service_usage_enabled:
#             # Enable the service usage
#             mgmt_group.properties.details.service_usage_enabled = True
#             management_groups_client.management_groups.create_or_update(
#                 group_id=root_management_group_id,
#                 create_management_group_request=mgmt_group
#             )
#         return True
#     except Exception as e:
#         logging.error(f"Failed to check or enable service usage for management group {root_management_group_id}: {e}")
#         return False

# """
# cyngular Activity function --  get subscriptions under root management group
# """
# @OnBoard.activity_trigger(input_name="input")
# def mgmt_group_subs(context: df.DurableActivityContext):
#     management_group_id = context.get_input()
#     try:
#         # Check if service usage is enabled for the root management group
#         usage_details = management_groups_client.management_groups.get_usage_details(root_management_group_id)
#         if not usage_details.enabled:
#             # Enable service usage if not already enabled
#             management_groups_client.management_groups.enable_service_usage(root_management_group_id)

#         subscriptions = []
#         result = {
#             "managementGroups": [],
#             "subscriptions": []
#         }
#         management_group = management_groups_client.management_groups.get(management_group_id)
#         for child in management_group.children:
#             if child.type == "Microsoft.Management/managementGroups":
#                 result["managementGroups"].append(child.name)
#             elif child.type == "Microsoft.Management/managementGroups/subscriptions":
#                 result["subscriptions"].append(child.name)
#         logging.warning("-- activity_trigger: got list of management groups and subscriptions --")
#         return result
#     except Exception:
#         logging.critical(traceback.format_exc())
#         return {"managementGroups": [], "subscriptions": []}

# def send_to_storage_account(outputs, resource_group_name=None, subscription_id=None):
#     try:
#         if(outputs[0]['resource_type_id'] == 8 or outputs[0]['resource_type_id'] == 9 or outputs[0]['resource_type_id'] == 10):
#             path = f"Global/{outputs[0]['cyngular_service_type']}/y={outputs[0]['year']:02}/m={outputs[0]['month']:02}/d={outputs[0]['day']:02}/h={outputs[0]['hour']:02}/PT1H.json"
#         else:
#             path = f"{subscription_id}/{resource_group_name}/{outputs[0]['cyngular_service_type']}/y={outputs[0]['year']:02}/m={outputs[0]['month']:02}/d={outputs[0]['day']:02}/h={outputs[0]['hour']:02}/PT1H.json"
#         logging.warning(f"SA path: {path}")
#         container_name = azure_config.AZURE_VISIBILITY_CLIENT_CONTAINER_NAME
#         storage_name = azure_config.AZURE_VISIBILITY_CLIENT_STORAGE_NAME
#         storage_key = azure_config.AZURE_VISIBILITY_CLIENT_STORAGE_KEY

#         blob_service_client = BlobServiceClient(account_url=f"https://{storage_name}.blob.core.windows.net", credential=storage_key)
#         container_client = blob_service_client.get_container_client(container=container_name)
#         new_json = json.dumps(outputs)

#         container_client.upload_blob(name=path, data=new_json, blob_type="BlockBlob", overwrite=True)
#         logging.warning("Sent to storage account")
#     except Exception as e:
#         logging.critical(f"{traceback.format_exc()}")