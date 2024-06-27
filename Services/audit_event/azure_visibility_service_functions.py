import azure_visibility_service_config as azure_config

from azure.storage.blob import BlobServiceClient
from azure.identity import ClientSecretCredential
from azure.mgmt.resource import SubscriptionClient
from azure.servicebus import ServiceBusClient, ServiceBusMessage

import logging
import traceback
import json
from datetime import datetime
import requests
from threading import Lock

mutex = Lock()

def json_to_lowercare(message):
    try:
        if isinstance(message, dict):
            for key, value in message.items():
                message[key] = json_to_lowercare(value)
        elif isinstance(message, list):
            for i in range(len(message)):
                message[i] = json_to_lowercare(message[i])
        elif isinstance(message, str):
            message = message.lower()
        return message
    except Exception as e:
        logging.critical(traceback.format_exc())

def get_client_credentials():

    try:
        credential = ClientSecretCredential(
            tenant_id=azure_config.AZURE_CLIENT_TENANT_ID,
            client_id=azure_config.AZURE_CLIENT_APPLICATION_ID,
            client_secret=azure_config.AZURE_CLIENT_APPLICATION_SECRET
        )
        return credential
    except Exception as e:
        if(not("Region configured (None) != region detected" in traceback.format_exc())):
            logging.critical(traceback.format_exc())
            raise Exception("Error getting client credentials")

def json_serial(x):
    if isinstance(x, datetime):
        return x.__str__()
    raise TypeError('unkonwn type')


def send_to_aws_by_parts(items):
    messages_total_size = 0
    temp_lst=[]
    for item in items:
        if messages_total_size + item.__sizeof__() < 10000:
            messages_total_size = messages_total_size + item.__sizeof__()
            temp_lst.append(item)
        else:
            logging.warning(f"Sending batch of {temp_lst.__sizeof__()} bytes")
            url = azure_config.AZURE_VISIBILITY_AWS_URL
            temp_lst = json.dumps(temp_lst)
            myobj = temp_lst
            x = requests.post(url, json = myobj)
            temp_lst = []
            temp_lst.append(item)
            messages_total_size = item.__sizeof__()
    if temp_lst:
        try:
            logging.warning(f"Sending batch of {temp_lst.__sizeof__()} bytes")
            url = azure_config.AZURE_VISIBILITY_AWS_URL
            temp_lst = json.dumps(temp_lst)
            response = requests.post(url, json = temp_lst)
            logging.error(f"AWS response status: {response}")
        except Exception as e:
            logging.critical(f"{traceback.format_exc()}")

def get_subscription_ids_list(credentials):
    #return a list that contains all the subscriptions in the account
    try:
        sub_list = []
        subscription_client = SubscriptionClient(credentials)

        subscriptions = subscription_client.subscriptions.list()

        for subscription in subscriptions:
            sub_list.append(subscription)
        
        subscription_id_list = []
        for item in sub_list:
            if azure_config.AZURE_CLIENT_TENANT_ID == item.tenant_id:
                subscription_id_list.append(
                    {'subscription_id': item.subscription_id,"subscription_name": item.display_name}
                )
        return subscription_id_list
    except Exception as e:
        raise Exception(f"Error when trying to get subscriptions id list. {e}")

    
def convert_dict_to_string(dictionary):
    try:
        new_dict = {}
        visited = set()  # Keep track of visited objects to avoid circular references

        for key, value in dictionary.items():
            if key not in visited:
                visited.add(key)
                if isinstance(value, dict):
                    new_dict[key] = convert_dict_to_string(value)
                elif hasattr(value, '__dict__'):
                    new_dict[key] = convert_dict_to_string(value.__dict__)
                elif isinstance(value, list):
                    new_dict[key] = [convert_dict_to_string(item.__dict__) if hasattr(item, '__dict__') else str(item) for item in value]
                else:
                    new_dict[key] = value

        return new_dict
    except Exception as excepion:
        logging.critical(f"{traceback.format_exc()}")
        return 

def send_to_storage_account(outputs, resource_group_name=None, subscription_id=None):
    try:
        if(outputs[0]['resource_type_id'] == 8 or outputs[0]['resource_type_id'] == 9 or outputs[0]['resource_type_id'] == 10):
            path = f"Global/{outputs[0]['cyngular_service_type']}/y={outputs[0]['year']:02}/m={outputs[0]['month']:02}/d={outputs[0]['day']:02}/h={outputs[0]['hour']:02}/PT1H.json"
        else:
            path = f"{subscription_id}/{resource_group_name}/{outputs[0]['cyngular_service_type']}/y={outputs[0]['year']:02}/m={outputs[0]['month']:02}/d={outputs[0]['day']:02}/h={outputs[0]['hour']:02}/PT1H.json"
        logging.warning(f"SA path: {path}")
        container_name = azure_config.AZURE_VISIBILITY_CLIENT_CONTAINER_NAME
        storage_name = azure_config.AZURE_VISIBILITY_CLIENT_STORAGE_NAME
        storage_key = azure_config.AZURE_VISIBILITY_CLIENT_STORAGE_KEY

        blob_service_client = BlobServiceClient(account_url=f"https://{storage_name}.blob.core.windows.net", credential=storage_key)
        container_client = blob_service_client.get_container_client(container=container_name)
        new_json = json.dumps(outputs)

        container_client.upload_blob(name=path, data=new_json, blob_type="BlockBlob", overwrite=True)
        logging.warning("Sent to storage account")
    except Exception as e:
        logging.critical(f"{traceback.format_exc()}")


def divide_list_into_sublists(input_list, num_sublists=5):
    sublists = []
    average_length = len(input_list) // num_sublists
    remainder = len(input_list) % num_sublists

    start = 0
    for i in range(num_sublists):
        sublist_length = average_length + 1 if i < remainder else average_length
        end = start + sublist_length
        sublists.append(input_list[start:end])
        start = end

    return sublists


def send_msgs_to_service_bus(message):
    """
    Send data to service bus, to store in Azure database.
    """
    logging.warning(f"Sending data to service bus")
    servicebus_client = ServiceBusClient.from_connection_string(azure_config.AZURE_SERVICE_BUS_CONN_STR)
    sender = servicebus_client.get_queue_sender(azure_config.AZURE_SERVICE_BUS_QUEUE_NAME)
    try:
        message_object = ServiceBusMessage(json.dumps(message, default=json_serial))
        sender.send_messages(message_object)
        logging.warning("Sent to service bus")
    except Exception as e:
        try:
            if 'exceeds the limit' in str(e):
                logging.critical(f"MessageSizeExceededError - Divide into 5 lists....")
                sublists = divide_list_into_sublists(message)
                for sublist in sublists:
                    message_object = ServiceBusMessage(json.dumps(sublist, default=json_serial))
                    with mutex:
                        sender.send_messages(message_object)
                logging.warning("Sent to service bus")
            else:
                logging.critical(f"{traceback.format_exc()}")
        except Exception as e:
            logging.critical(f"{traceback.format_exc()}")

def get_parent_resource_id(storage_account_id):
    try:
        parts = storage_account_id.split("/")
        subscription_index = parts.index("subscriptions")
        parent_resource_id = "/".join(parts[:subscription_index + 4])
        return parent_resource_id
    except Exception as e:
        logging.critical(f"Error when getting parent resource id {e}")
        return ""

def create_client_container_if_not_exist():
    """
    Check if a container for storing data exists. If not - create it.
    """
    try:
        container_name = azure_config.AZURE_VISIBILITY_CLIENT_CONTAINER_NAME
        storage_name = azure_config.AZURE_VISIBILITY_CLIENT_STORAGE_NAME
        storage_key = azure_config.AZURE_VISIBILITY_CLIENT_STORAGE_KEY
        blob_service_client = BlobServiceClient(account_url=f"https://{storage_name}.blob.core.windows.net", credential=storage_key)
        container_client = blob_service_client.get_container_client(container=container_name)
        exists = container_client.exists()

        if not exists:
            logging.warning(f"Creating a container for storing data. New container name:{container_name}")
            response = container_client.create_container()
            return response
        else:
            logging.warning(f"Container {container_name} already exists")
            return True
    except Exception as e:
        logging.critical(f"{traceback.format_exc()}")
        return False
        

