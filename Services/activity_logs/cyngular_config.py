import logging
import traceback
import os

from azure.keyvault.secrets import SecretClient
from azure.identity import ManagedIdentityCredential

try:
    logging.basicConfig(filename='os_volume_service.log', filemode='a', format='%(asctime)s - %(levelname)s - %(message)s', level=logging.INFO)
    logging.info('Starting os service config file')
    AZURE_SECRET_NAME = ""
    AZURE_CYNGULAR_SUBSCRIPTION_ID = ""
    
    if os.environ['AZURE_SECRET_NAME']:
        AZURE_SECRET_NAME = os.environ['AZURE_SECRET_NAME']
    else:
        raise ValueError('Missing AZURE_SECRET_NAME')
    if os.environ['SUBSCRIPTION_ID']:
        AZURE_CYNGULAR_SUBSCRIPTION_ID = os.environ['SUBSCRIPTION_ID']
    else:
        raise ValueError('Missing AZURE_SECRET_NAME')

    logging.info('Connecting to keyvault')
    KVUri = f"https://{AZURE_SECRET_NAME}.vault.azure.net"

    credential = ManagedIdentityCredential()
    client = SecretClient(vault_url=KVUri, credential=credential)   

    AZURE_CLIENT_NAME = client.get_secret("AZURE-CLIENT-NAME").value
    if not AZURE_CLIENT_NAME:
        raise ValueError('Missing AZURE_CLIENT_NAME')

    AZURE_CLIENT_TENANT_ID = client.get_secret("AZURE-CLIENT-TENANT-ID").value
    if not AZURE_CLIENT_TENANT_ID:
        raise ValueError('Missing AZURE_CLIENT_TENANT_ID')


    AZURE_CLIENT_APPLICATION_ID = client.get_secret("AZURE-CLIENT-APPLICATION-ID").value
    if not AZURE_CLIENT_APPLICATION_ID:
        raise ValueError('Missing AZURE_CLIENT_APPLICATION_ID')


    AZURE_CLIENT_APPLICATION_SECRET = client.get_secret("AZURE-CLIENT-APPLICATION-SECRET").value
    if not AZURE_CLIENT_APPLICATION_SECRET:
        raise ValueError('Missing AZURE_CLIENT_APPLICATION_SECRET')


    AZURE_CYNGULAR_CLIENT_RG = client.get_secret("AZURE-CYNGULAR-CLIENT-RG").value
    if not AZURE_CYNGULAR_CLIENT_RG:
        raise ValueError('Missing AZURE_CYNGULAR_CLIENT_RG')


    AZURE_CYNGULAR_SNAPSHOTS_STORAGE_NAME = client.get_secret("AZURE-CYNGULAR-SNAPSHOTS-STORAGE-NAME").value
    if not AZURE_CYNGULAR_SNAPSHOTS_STORAGE_NAME:
        raise ValueError('Missing AZURE_CYNGULAR_SNAPSHOTS_STORAGE_NAME')


    AZURE_CYNGULAR_STORAGE_SS_CONTAINER_NAME = client.get_secret("AZURE-CYNGULAR-STORAGE-SS-CONTAINER-NAME").value
    if not AZURE_CYNGULAR_STORAGE_SS_CONTAINER_NAME:
        raise ValueError('Missing AZURE_CYNGULAR_STORAGE_SS_CONTAINER_NAME')


    AZURE_LINUX_SERVICE_BUS_CONN_STR_2 = client.get_secret("AZURE-LINUX-SERVICE-BUS-CONN-STR-2").value
    if not AZURE_LINUX_SERVICE_BUS_CONN_STR_2:
        raise ValueError('Missing AZURE-LINUX-SERVICE-BUS-CONN-STR-2')


    AZURE_LINUX_SERVICE_QUEUE_NAME_2 = client.get_secret("AZURE-LINUX-SERVICE-QUEUE-NAME-2").value
    if not AZURE_LINUX_SERVICE_QUEUE_NAME_2:
        raise ValueError('Missing AZURE-LINUX-SERVICE-QUEUE-NAME-2')       
    
    
    INSTANCES_PER_SERVER = client.get_secret("INSTANCES-PER-SERVER").value
    if not INSTANCES_PER_SERVER:
        raise ValueError('INSTANCES_PER_SERVER')
        
    AZURE_OS_SUBNET_ID = client.get_secret("AZURE-OS-SUBNET-ID").value
    if not AZURE_OS_SUBNET_ID:
        raise ValueError("AZURE_OS_SUBNET_ID")

    AZURE_LINUX_IMAGE_ID = client.get_secret("AZURE-LINUX-IMAGE-ID").value
    if not AZURE_LINUX_IMAGE_ID:
        raise ValueError("AZURE_LINUX_IMAGE_ID")

    AZURE_WINDOWS_IMAGE_ID = client.get_secret("AZURE-WINDOWS-IMAGE-ID").value
    if not AZURE_WINDOWS_IMAGE_ID:
        raise ValueError("AZURE_WINDOWS_IMAGE_ID")

    AZURE_WINDOWS_SERVICE_BUS_CONN_STR_2 = client.get_secret("AZURE-WINDOWS-SERVICE-BUS-CONN-STR-2").value
    if not AZURE_WINDOWS_SERVICE_BUS_CONN_STR_2:
        raise ValueError('Missing AZURE-WINDOWS-SERVICE-BUS-CONN-STR-2')

    AZURE_WINDOWS_SERVICE_QUEUE_NAME_2 = client.get_secret("AZURE-WINDOWS-SERVICE-QUEUE-NAME-2").value
    if not AZURE_WINDOWS_SERVICE_QUEUE_NAME_2:
        raise ValueError('Missing AZURE-WINDOWS-SERVICE-QUEUE-NAME-2')

    logging.info('Secrets were exported successfully')

except Exception as e:
        logging.critical(traceback.format_exc())
        exit()