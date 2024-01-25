import subprocess
import json
import shlex
import traceback
import logging
import time
from multiprocessing import Process

PRINCIPAL_NAME = "cyngularSP"
CLIENT_NAME = "xxxxxxxxxx"
RESOURCE_GROUP = "cyngularRG"
RESOURCE_GROUP_LOCATION = "xxxxxxxxxx"
AUDIT_STORAGE_ACCOUNT_NAME = f"cyngularaudit{CLIENT_NAME}"
NSG_STORAGE_ACCOUNT_NAME = f"cyngularnsg{CLIENT_NAME}xxxxxxxxxx"
ACTIVITY_FILE_NAME = "activity-log.bicep"

LOG_SETTINGS = "\"[{category:AuditEvent,enabled:true,retention-policy:{enabled:false,days:30}}]\""
METRIC_SETTINGS = "\"[{category:AllMetrics,enabled:true,retention-policy:{enabled:false,days:30}}]\""

logging.basicConfig(
    filename="cyngular_onboarding.log",
    filemode="a",
    format="%(asctime)s - %(levelname)s - %(message)s",
    level=logging.INFO,
)

def azcli(cli_args, verbose=True):
    try:
        cli_args = shlex.split(cli_args)
        process = subprocess.Popen(
            cli_args, stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
        out, err = process.communicate()
        exit_code = process.returncode
        if exit_code and exit_code != 0:
            raise ValueError(str(err) + '  "' + " ".join(cli_args) + '"')
        elif len(out) == 0:
            return out
        else:
            return json.loads(out)
    except Exception:
        # if("was not found" in traceback.format_exc()):
        #     return
        # elif("does not support diagnostic settings" in traceback.format_exc()):
        #     return
        # elif("'AuditEvent' is not supported" in traceback.format_exc()):
        #     return
        # elif("could not be found" in traceback.format_exc()):
        #     return
        if verbose:
            logging.critical(traceback.format_exc())
        else:
            raise Exception(traceback.format_exc())

def get_subscription_lst(): #v
    try:
        logging.info("Collecting client subscriptions id")
        print("Collecting client subscriptions id")
        cli_args = "az account subscription list --query [].subscriptionId"
        return azcli(cli_args)
    except Exception as e:
        raise Exception(str(e))

def create_cyngular_service_principal(): #v
    try:
        logging.info("Creating cyngular service principal")
        print("Creating cyngular service principal")
        cli_args = f"az ad sp create-for-rbac --name {PRINCIPAL_NAME}" # require aministrator role
        res = azcli(cli_args)

        principal_app_id = res["appId"]
        principal_password = res["password"]
        principal_tenant = res["tenant"]

        return principal_app_id, principal_password, principal_tenant
    except Exception as e:
        raise Exception(str(e))

def set_subscription(subscription_id: str): #v
    try:
        cli_args = f"az account set --subscription {subscription_id}"
        _ = azcli(cli_args)
    except Exception:
        logging.critical(f"{traceback.format_exc()}")

def get_principal_object_id(principal_app_id: str): #v
    try:
        cli_args = f"az ad sp show --id {principal_app_id} --query id"
        principal_object_id = azcli(cli_args)
        return principal_object_id
    except Exception as e:
        raise Exception(str(e))

def assign_subscription_role(subscription_id: str, principal_object_id: str, role: str): #v
    try:
        cli_args = f'az role assignment create --assignee-object-id {principal_object_id} --assignee-principal-type ServicePrincipal --role "{role}" --scope /subscriptions/{subscription_id}'
        _ = azcli(cli_args)
    except Exception:
        logging.critical(f"{traceback.format_exc()}")

def create_resource_group(resource_group_location, resource_group_name): #v +
    try:
        logging.info(f"Creating {resource_group_name} resource group")
        print(f"Creating {resource_group_name} resource group")
        cli_args = (
            f"az group create -l {resource_group_location} -n {resource_group_name}"
        )
        azcli(cli_args)
    except Exception as e:
        if resource_group_name == RESOURCE_GROUP:
            raise Exception(str(e))
        else:
            logging.critical(f"{traceback.format_exc()}")

def create_audit_storage_account(audit_storage_account_name, company_region): #v
    try:
        logging.info("Creating audit storage account")
        print("Creating audit storage account")
        cli_args = f"az storage account list --resource-group {RESOURCE_GROUP} --query \"[?name=='{audit_storage_account_name}'].id\""
        res = azcli(cli_args)
        # create new storage account if there is no audit storage account in  cyngular resource group
        if len(res) == 0:
            cli_args = f"az storage account create -n {audit_storage_account_name} -g {RESOURCE_GROUP} -l {company_region} --sku Standard_LRS --default-action Allow --bypass Logging Metrics AzureServices"
            audit_storage_account_id = azcli(cli_args)["id"]
            return audit_storage_account_id

    except Exception as e:
        raise Exception(str(e))

def create_nsg_storage_account(nsg_storage_account_name, company_region): #v
    try:
        logging.info("Creating nsg storage account")
        print("Creating nsg storage account")
        cli_args = f"az storage account list --resource-group {RESOURCE_GROUP} --query \"[?name=='{nsg_storage_account_name}'].id\""
        # create new storage account if there is no nsg storage account in  cyngular resource group
        if len(azcli(cli_args)) == 0:
            cli_args = f"az storage account create -n {nsg_storage_account_name} -g {RESOURCE_GROUP} -l {company_region} --sku Standard_LRS"
            nsg_storage_account_id = azcli(cli_args)["id"]
            return nsg_storage_account_id
    except Exception as e:
        raise Exception(str(e))

def get_storage_accounts_connection_string(audit_storage_account_name, nsg_storage_account_name): #v
    try:
        logging.info("Getting the storage accounts connection strings")
        cli_args = f"az storage account show-connection-string -g {RESOURCE_GROUP} -n {audit_storage_account_name} --query connectionString"
        audit_connection_string = azcli(cli_args)
        cli_args = f"az storage account show-connection-string -g {RESOURCE_GROUP} -n {nsg_storage_account_name} --query connectionString"
        nsg_connection_string = azcli(cli_args)
        return audit_connection_string, nsg_connection_string
    except Exception:
        logging.critical(f"{traceback.format_exc()}")

def export_activity_logs(subscription: str, audit_storage_account_id: str, company_region: str): #v +
    try:
        logging.info(f"Exporting activity logs from subscription: {subscription}")
        print(f"Exporting activity logs from subscription: {subscription}")
        cli_args = f"az deployment sub create --location {company_region} --template-file {ACTIVITY_FILE_NAME}  --parameters settingName=cyngularDiagnostic storageAccountId={audit_storage_account_id}"
        _ = azcli(cli_args)
    except Exception:
        logging.critical(f"{traceback.format_exc()}")

def import_diagnostic_settings(audit_storage_account_id, company_region): #v ++
    try:
        logging.info(f"Importing diagnostic settings")
        print(f"Importing diagnostic settings")
        resource_ids_cli = f"az resource list --location {company_region} --query \"[].id\""
        resource_ids = azcli(resource_ids_cli)
        reasource = ""
        #add type conditions
        for reasource in resource_ids:
            if("Microsoft.Network" in reasource):
                cli_args = f"az monitor diagnostic-settings create --name cyngularDiagnostic --resource {reasource} --storage-account {audit_storage_account_id} --logs {LOG_SETTINGS}"
                _ = azcli(cli_args)
            else:
                cli_args = f"az monitor diagnostic-settings create --name cyngularDiagnostic --resource {reasource} --storage-account {audit_storage_account_id} --logs {LOG_SETTINGS} --metric {METRIC_SETTINGS}"
                _ = azcli(cli_args)
    except Exception as e:
        logging.critical(f"{traceback.format_exc()}")

def get_resource_groups(): #v +
    try:
        cli_args = f"az group list"
        res = azcli(cli_args)

        resource_groups = []
        for group in res:
            resource_group = {
                "name": group["name"],
                "id": group["id"],
                "location": group["location"],
            }
            resource_groups.append(resource_group)
        return resource_groups
    except Exception:
        logging.critical(f"{traceback.format_exc()}")


def get_network_interfaces(subscription_resource_group: str): #v +
    try:
        logging.info(
            f"Collecting nsg flow logs from resource group: {subscription_resource_group}"
        )
        print(
            f"Collecting nsg flow logs from resource group: {subscription_resource_group}"
        )

        cli_args = f"az network nsg list --resource-group {subscription_resource_group}"
        res = azcli(cli_args)

        network_interfaces_lst = []
        for nsg in res:
            network_interface = {"id": nsg["id"], "location": nsg["location"]}
            network_interfaces_lst.append(network_interface)
        return network_interfaces_lst

    except Exception:
        logging.critical(f"{traceback.format_exc()}")


def is_network_watcher_in_location(location: str): #v +
    try:
        cli_args = f"az network watcher list --query \"[?location=='{location}'].id\""
        if azcli(cli_args) == None:
            return True
        return False
    except Exception:
        logging.critical(f"{traceback.format_exc()}")


def network_watcher_configure(location: str): #v +
    try:
        cli_args = f"az network watcher configure -g NetworkWatcherRG  -l {location} --enabled true"
        azcli(cli_args)
    except Exception as e:
        # if "NetworkWatcherCountLimitReached" not in str(e):
            # logging.critical(f"{traceback.format_exc()}")
        logging.critical(f"{traceback.format_exc()}")


def create_nsg_flowlog(location: str, network_interface_id: str, nsg_storage_account_id: str): #v +
    try:
        cli_args = f"az network watcher flow-log create --location {location} --name cyngular --nsg {network_interface_id} --storage-account {nsg_storage_account_id}"
        azcli(cli_args)
    except Exception:
        logging.critical(f"{traceback.format_exc()}")


def subscription_manager(company_region, subscription, principal_object_id, audit_storage_account_id, nsg_storage_account_id): #v ++
    try:
        logging.info(f"\n The current subscription is: {subscription}")
        print(f"\n The current subscription is: {subscription}")
        set_subscription(subscription)

        # assigning cyngular service princicpal the required roles in the
        assign_subscription_role(subscription, principal_object_id, "Reader")
        assign_subscription_role(subscription, principal_object_id, "Disk Pool Operator")
        assign_subscription_role(subscription, principal_object_id, "Data Operator for Managed Disks")
        assign_subscription_role(subscription, principal_object_id, "Disk Snapshot Contributor")
        assign_subscription_role(subscription, principal_object_id, "Microsoft Sentinel Reader")

        # exporting activity logs from the subscription
        export_activity_logs(subscription, audit_storage_account_id, company_region)
        
        # create network watcher resource group
        create_resource_group(company_region, "NetworkWatcherRG")

        # getting the subscription resource group
        resource_groups = get_resource_groups()

        for subscription_resource_group in resource_groups:
            try:
                network_interface_lst = get_network_interfaces(subscription_resource_group["name"])
                
                # configurating network watcher on resource group location
                if (is_network_watcher_in_location(subscription_resource_group["location"])
                    == False):
                    network_watcher_configure(subscription_resource_group["location"])

                for network_interface in network_interface_lst:
                    try:
                        # configurating network watcher on network interface location
                        if (is_network_watcher_in_location(network_interface["location"]) == False):
                            network_watcher_configure(
                                network_interface["location"])
                        # creating nsg flow log
                        if network_interface["location"] == "northeurope":
                            create_nsg_flowlog(
                                network_interface["location"],
                                network_interface["id"],
                                nsg_storage_account_id,
                            )
                        else:
                            logging.info(
                                "NSG is not located in North Europe, skiping"
                            )
                            print("NSG is not located in North Europe, skiping")
                            logging.info(
                                f"LOCATION: {network_interface['location']}"
                            )
                            print(f"LOCATION: {network_interface['location']}")
                            logging.info(f"ID: {network_interface['id']}")
                            print(f"ID: {network_interface['id']}")
                    except Exception:
                        logging.critical(f"{traceback.format_exc()}")
            except Exception:
                logging.critical(f"{traceback.format_exc()}")
    except Exception:
        logging.critical(f"{traceback.format_exc()}")

def main():
    try:
        t0 = time.time()
        logging.info("STARTING CYNGULAR ONBOARING PROCESS")
        print("STARTING CYNGULAR ONBOARING PROCESS")
        print("=====================================\n")

        company_region = input("Please Enter Your Company Main Region Here: ")
        company_name = input("Please Enter Your Company Name Here: ")
        nsg_storage_account_name = "cyngularnsg" + company_name + company_region
        while(len(company_name) > 24 or len(company_name + company_region) > 24 or len("cyngularaudit" + company_name) > 24 or len(nsg_storage_account_name) > 24):
            if(len("cyngularnsg" + company_name + company_region) > 24):
                nsg_storage_account_name = "cyngularnsg" + company_name + company_region[0:3]
                if(len(nsg_storage_account_name) > 24):
                    company_name = input("\n*Your Company Name Is Too Long\nPlease Re-Enter Your Company Name Here: ")
        audit_storage_account_name = "cyngularaudit" + company_name 

        # getting the client subscription ids
        subscriptions_lst = get_subscription_lst()

        # creating cyngular's service principal
        (
            principal_app_id,
            principal_password,
            principal_tenant,
        ) = create_cyngular_service_principal()
        principal_object_id = get_principal_object_id(principal_app_id)

        # creating cyngular's storage accounts resource group
        create_resource_group(company_region, RESOURCE_GROUP)

        # creating cyngular storage accounts
        audit_storage_account_id = create_audit_storage_account(audit_storage_account_name, company_region)
        nsg_storage_account_id = create_nsg_storage_account(nsg_storage_account_name, company_region)
        
        (
            audit_connection_string,
            nsg_connection_string,
        ) = get_storage_accounts_connection_string(audit_storage_account_name, nsg_storage_account_name)

        for subscription in subscriptions_lst:       
            p = Process(target=subscription_manager, args=(company_region, subscription, principal_object_id, audit_storage_account_id, nsg_storage_account_id))
            p.start()
            p.join()

        # importing diagnostic settings for the resource
        import_diagnostic_settings(audit_storage_account_id, company_region)

        logging.info("FINISHED ONBOARDING")
        logging.info("COPY FROM HERE:")
        logging.info(f"Service Principal App ID: {principal_app_id}")
        logging.info(f"Service Principal Password: {principal_password}")
        logging.info(f"Service Principal Tenant: {principal_tenant}")
        logging.info(f"Service Principal Audit Storage Account Connection String: {audit_connection_string}")
        logging.info(f"Service Principal NSG Storage Account Connection String: {nsg_connection_string}")
        
        print("FINISHED ONBOARDING")
        print("COPY FROM HERE:")
        print(f"Service Principal App ID: {principal_app_id}")
        print(f"Service Principal Password: {principal_password}")
        print(f"Service Principal Tenant: {principal_tenant}")
        print(f"Service Principal Audit Storage Account Connection String: {audit_connection_string}")
        print(f"Service Principal NSG Storage Account Connection String: {nsg_connection_string}")
        
        t1 = time.time()
        print(f"onbooarding took:\t {t1-t0}")
    except Exception:
        logging.critical(f"{traceback.format_exc()}")

if __name__ == "__main__":
    main()