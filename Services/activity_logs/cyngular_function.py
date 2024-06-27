import azure_os_volume_service_config as azure_config
import logging
import traceback

import string
import random
import uuid

from azure.identity import ClientSecretCredential, ManagedIdentityCredential
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.network import NetworkManagementClient



def get_cyngular_credentials():
    try:
       return ManagedIdentityCredential()
    except Exception as e:
        logging.critical(traceback.format_exc())
        raise Exception("Error getting cyngular credentials")
    
def get_rg_location(rg_name: str, credentials: ClientSecretCredential | ManagedIdentityCredential, subscription_id : str):
    try:
        resource_client = ResourceManagementClient(credentials, subscription_id)
        rg_object = resource_client.resource_groups.get(rg_name)
        return rg_object.location
    except Exception as e:
        logging.critical(traceback.format_exc())

def create_resource_group(credentials: ClientSecretCredential | ManagedIdentityCredential, subscription_id : str,rg_name):
    try:
        resource_client = ResourceManagementClient(credentials, subscription_id)
        rg_result = resource_client.resource_groups.create_or_update(rg_name, {"location":get_rg_location(azure_config.AZURE_CYNGULAR_RG,credentials,subscription_id) })  
        logging.warning(f"Provisioned resource group {rg_result.name} in the {rg_result.location} region")             
    except Exception as e:
        logging.critical(traceback.format_exc())

def create_nic(credentials: ClientSecretCredential | ManagedIdentityCredential, subscription_id : str,rg_name, nic_name, subnet_id):
    try:
        network_client = NetworkManagementClient(credentials, subscription_id)
        poller = network_client.network_interfaces.begin_create_or_update(
        rg_name,
        nic_name,
        {
            "location": get_rg_location(rg_name, credentials, subscription_id),
            "ip_configurations": [
                {
                    "name": f'{nic_name}-config',
                    "subnet": {"id": subnet_id},
                    "private_ip_allocation_method": 'Dynamic'
                }
            ],
        },
        )

        nic_result = poller.result()
        return nic_result
    except Exception as e:
        logging.critical(traceback.format_exc())

def calculate_required_servers(num_of_instances, instances_per_server):
    try:
        num_of_instances = int(num_of_instances)
        instances_per_server = int(instances_per_server)
        if num_of_instances / instances_per_server % 1 != 0:
            return int(num_of_instances / instances_per_server) + 1
        else:
            return int(num_of_instances / instances_per_server)
    except Exception as ex:
        raise Exception(traceback.format_exc())

def assign_vm_roles(authorization_client, linux_role, vm_result, keyvault_role, rg_name):
    try:
        role_assignment = authorization_client.role_assignments.create(f"/subscriptions/{azure_config.AZURE_CYNGULAR_SUBSCRIPTION_ID}/resourceGroups/{rg_name}", uuid.uuid4(),
            {
                'role_definition_id': linux_role.id,
                'principal_id': vm_result.identity.principal_id
            }
        )

        role_assignment = authorization_client.role_assignments.create(f"/subscriptions/{azure_config.AZURE_CYNGULAR_SUBSCRIPTION_ID}/resourceGroups/{rg_name}", uuid.uuid4(),
            {
                'role_definition_id': keyvault_role.id,
                'principal_id': vm_result.identity.principal_id
            }
        )
    except Exception as ex:
        raise Exception(traceback.format_exc())


def generate_password():
    upper = string.ascii_uppercase
    lower = string.ascii_lowercase
    digits = string.digits
    special = string.punctuation.replace("'", "").replace('"', "").replace("`", "")
    
    password = []
    
    # Add at least one character from each category
    password.append(random.choice(upper))
    password.append(random.choice(lower))
    password.append(random.choice(digits))
    password.append(random.choice(special))
    
    # Fill the rest of the password with random characters
    remaining_length = random.randint(2, 68)
    for _ in range(remaining_length):
        chars = [upper, lower, digits, special]
        category = random.choice(chars)
        password.append(random.choice(category))
    
    # Shuffle the password to randomize it
    random.shuffle(password)
    
    return ''.join(password)
