import logging
import subprocess
import json
import shlex
import azure.functions as func

# logging.basicConfig(
#     filename="onboarding_audit.log",
#     filemode="a",
#     format="%(asctime)s - %(levelname)s - %(message)s",
#     level=logging.INFO,
# )

app = func.FunctionApp(auth_level=func.AuthLevel.ANONYMOUS)

# @app.function_name(name="HttpTrigger1")
@app.route(route="dvir")
def diagnostic(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')
    # vm_resource_id = "/subscriptions/373cb248-9e3b-4f65-8174-c72d253103ea/resourceGroups/stark-rg/providers/Microsoft.KeyVault/vaults/stark-keyvault"
    # storage_account_id = "/subscriptions/373cb248-9e3b-4f65-8174-c72d253103ea/resourceGroups/cyngular-tesla-rg/providers/Microsoft.Storage/storageAccounts/cyngularteslawestus2"

    # args = f"""az monitor diagnostic-settings create --name CyngularDiagnostic --resource {vm_resource_id} --storage-account {storage_account_id} --logs '{ALL_AND_AUDIT_LOG_SETTINGS}'"""
    # result = azure_cli(shlex.split(args))
    # if result == 'error':
    #     return func.HttpResponse("Error applying diagnostic settings", status_code=500)

    return func.HttpResponse(
        "Diagnostic settings applied successfully.",
        status_code=200
        )

# ALL_AND_AUDIT_LOG_SETTINGS = '[{"categoryGroup":"audit","enabled":true,"retention-policy":{"enabled":false,"days":30}},{"categoryGroup":"allLogs","enabled":true,"retention-policy":{"enabled":false,"days":30}}]'

# def azure_cli(command):
#     # Splitting the command into parts for subprocess
#     command_parts = shlex.split(command)

#     try:
#         # Execute the command
#         result = subprocess.run(command_parts, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

#         # Extracting the output
#         output = result.stdout
#         try:
#             # Trying to parse the output as JSON
#             json_output = None
#             json_output = json.loads(output)
#             return json_output
#         except json.JSONDecodeError:
#             # Output is not JSON
#             return output

#     except subprocess.CalledProcessError as e:
#         # There was an error executing the command
#         if 'does not support diagnostic settings' not in e.stderr and 'is not supported' not in e.stderr:
#             print(f"Command (error): {command}")
#             print(f"Error: {e}")
#             logging.info(f"Error: {e}")
#             logging.info(f"Error Output: {e.stderr}")
#             return 'error'
