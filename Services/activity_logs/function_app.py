import logging
import traceback

import azure.durable_functions as df
import azure.functions as func

# OnBoard = func.FunctionApp()
OnBoard = df.DFApp(func.AuthLevel.ANONYMOUS)

@OnBoard.route(route="functionO/")
@OnBoard.durable_client_input(client_name="client")
async def durable_trigger_functionO(req: func.HttpRequest, client):
#@OnBoard.durable_client_input(client_name="client")
#@OnBoard.schedule(schedule="30 1-4 * * *",
#            arg_name="DailyTimer",
#            run_on_startup=True)
#async def durable_trigger_functionO(DailyTimer: func.TimerRequest, client):
    instance_id = await client.start_new("os_service_function")
    response = client.create_check_status_response(req, instance_id)
    return response



@OnBoard.function_name(name="DS")
@OnBoard.route(route="hello", auth_level=func.AuthLevel.ANONYMOUS)
def test_function(req: func.HttpRequest) -> func.HttpResponse:
    
    vm_resource_id = "/subscriptions/373cb248-9e3b-4f65-8174-c72d253103ea/resourceGroups/stark-rg/providers/Microsoft.KeyVault/vaults/stark-keyvault"
    storage_account_id = "/subscriptions/373cb248-9e3b-4f65-8174-c72d253103ea/resourceGroups/cyngular-tesla-rg/providers/Microsoft.Storage/storageAccounts/cyngularteslawestus"

    create_diagnostic_settings(vm_resource_id, storage_account_id)

    logging.warning('Python HTTP trigger function processed a request.')
    return func.HttpResponse(
        "This HTTP triggered function executed successfully.",
        status_code=200
        )

# """
# cyngulat trigger for services
# """
@OnBoard.orchestration_trigger(context_name="context")
def os_service_function(context: df.DurableOrchestrationContext):
    try:
        service_bus_client_linux = ServiceBusAdministrationClient.from_connection_string(azure_config.AZURE_LINUX_SERVICE_BUS_CONN_STR_2)
        queue_props_linux = service_bus_client_linux.get_queue_runtime_properties(azure_config.AZURE_LINUX_SERVICE_QUEUE_NAME_2)
        message_count_linux = queue_props_linux.total_message_count

        service_bus_client_windows = ServiceBusAdministrationClient.from_connection_string(azure_config.AZURE_WINDOWS_SERVICE_BUS_CONN_STR_2)
        queue_props_windows = service_bus_client_windows.get_queue_runtime_properties(azure_config.AZURE_WINDOWS_SERVICE_QUEUE_NAME_2)
        message_count_windows = queue_props_windows.total_message_count

        # calculated requierd number of VMs based on total number of messages in Queue for linux and Windows
        calculated_servers_linux = azure_func.calculate_required_servers(message_count_linux, azure_config.INSTANCES_PER_SERVER)
        calculated_servers_windows = azure_func.calculate_required_servers(message_count_windows, azure_config.INSTANCES_PER_SERVER)

        logging.warning(f"Running over {message_count_linux} linux messages and Creating {calculated_servers_linux} linux servers (vm's)")
        logging.warning(f"Running over {message_count_windows} windows messages and Creating {calculated_servers_windows} windows servers (vm's)")
        
        parallel_task_linux = [context.call_activity("create_roles_and_vm", "Linux") for vm_number in (range(calculated_servers_linux))]
        parallel_task_windows = [context.call_activity("create_roles_and_vm", "Windows") for vm_number in (range(calculated_servers_windows))]
        
        parallel_tasks = parallel_task_linux + parallel_task_windows
        yield context.task_all(parallel_tasks)
    except:
        logging.critical(traceback.format_exc())
    return 0