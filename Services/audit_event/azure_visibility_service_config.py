import logging
import traceback

from azure.keyvault.secrets import SecretClient
from azure.identity import ManagedIdentityCredential
 
import os


try:
    logging.basicConfig(
        filename="cloud_service.log",
        filemode="a",
        format="%(asctime)s - %(levelname)s - %(message)s",
        level=logging.WARNING,
    )
    logging.warning("Starting cloud service config file")

    environ = os.environ.get("AZURE_SECRET_NAME")
    version = os.environ.get("AZURE_VISIBILITY_VERSION")

    if not environ:
        raise ValueError("Missing AZURE_SECRET_NAME")
    AZURE_SECRET_NAME = environ
    logging.warning("Connecting to azure identity")

    if not version:
        raise ValueError("Missing AZURE_VISIBILITY_VERSION")
    AZURE_VISIBILITY_VERSION = version

    KVUri = f"https://{AZURE_SECRET_NAME}.vault.azure.net"

    credential = ManagedIdentityCredential()
    client = SecretClient(vault_url=KVUri, credential=credential)

    logging.warning("Connecting to keyvault")

    AUTH0_CLIENT_ID = client.get_secret("AUTH0-CLIENT-ID").value
    if not AUTH0_CLIENT_ID:
        raise ValueError("Missing AUTH0_CLIENT_ID")

    AZURE_CLIENT_TENANT_ID = client.get_secret("AZURE-CLIENT-TENANT-ID").value
    if not AZURE_CLIENT_TENANT_ID:
        raise ValueError("Missing AZURE_CLIENT_TENANT_ID")

    AZURE_CLIENT_APPLICATION_ID = client.get_secret(
        "AZURE-CLIENT-APPLICATION-ID"
    ).value
    if not AZURE_CLIENT_APPLICATION_ID:
        raise ValueError("Missing AZURE_CLIENT_APPLICATION_ID")

    AZURE_CLIENT_APPLICATION_SECRET = client.get_secret(
        "AZURE-CLIENT-APPLICATION-SECRET"
    ).value
    if not AZURE_CLIENT_APPLICATION_SECRET:
        raise ValueError("Missing AZURE_CLIENT_APPLICATION_SECRET")
    
    AZURE_VISIBILITY_CLIENT_CONTAINER_NAME = client.get_secret("AZURE-VISIBILITY-CLIENT-CONTAINER-NAME").value
    if not AZURE_VISIBILITY_CLIENT_CONTAINER_NAME:
        raise ValueError("Missing AZURE-VISIBILITY-CLIENT-CONTAINER-NAME")
    
    AZURE_VISIBILITY_CLIENT_STORAGE_KEY = client.get_secret("AZURE-VISIBILITY-CLIENT-STORAGE-KEY").value
    if not AZURE_VISIBILITY_CLIENT_STORAGE_KEY:
        raise ValueError("Missing AZURE-VISIBILITY-CLIENT-STORAGE-KEY")
    
    AZURE_VISIBILITY_CLIENT_STORAGE_NAME = client.get_secret("AZURE-VISIBILITY-CLIENT-STORAGE-NAME").value
    if not AZURE_VISIBILITY_CLIENT_STORAGE_NAME:
        raise ValueError("Missing AZURE-VISIBILITY-CLIENT-STORAGE-NAME")

    AZURE_VISIBILITY_AWS_URL = client.get_secret("AZURE-VISIBILITY-AWS-URL").value
    if not AZURE_VISIBILITY_AWS_URL:
        raise ValueError("Missing AZURE-VISIBILITY-AWS-URL")
    
    AZURE_SERVICE_BUS_QUEUE_NAME = client.get_secret(
        "AZURE-SERVICE-BUS-QUEUE-NAME"
    ).value
    if not AZURE_SERVICE_BUS_QUEUE_NAME:
        raise ValueError("Missing AZURE-SERVICE-BUS-QUEUE-NAME")

    AZURE_SERVICE_BUS_CONN_STR = client.get_secret(
        "AZURE-SERVICE-BUS-CONN-STR"
    ).value
    if not AZURE_SERVICE_BUS_CONN_STR:
        raise ValueError("Missing AZURE-SERVICE-BUS-CONN-STR")

    logging.warning("Secrets were exported successfully")

except Exception:
    logging.critical(f"{traceback.format_exc()}")
    exit()