import azure_visibility_service_config as azure_config
import msal
import requests
import logging
import traceback

graphURI = 'https://graph.microsoft.com'

def msgraph_auth():
    try:
        logging.info('Graph api authentication function')
        authority = 'https://login.microsoftonline.com/' + azure_config.AZURE_CLIENT_TENANT_ID
        scope = ['https://graph.microsoft.com/.default']
        app = msal.ConfidentialClientApplication(azure_config.AZURE_CLIENT_APPLICATION_ID, authority=authority, client_credential=azure_config.AZURE_CLIENT_APPLICATION_SECRET)

        logging.info('Try to get access token without user interaction')
        accessToken = app.acquire_token_silent(scope, account=None)
        if not accessToken:
            logging.info('Try to get access token for current client')
            accessToken = app.acquire_token_for_client(scopes=scope)
            if accessToken['access_token']:
                logging.info('New access token retreived....')
                requestHeaders = {'Authorization': 'Bearer ' + accessToken['access_token']}
            else:
                logging.info('Error aquiring authorization token. Check your tenantID, clientID and clientSecret.')
        return requestHeaders
    except Exception as e:
        logging.critical(f"{traceback.format_exc()}")

def msgraph_request(resource, requestHeaders):
    try:
        logging.warning('Send requests to the MSGraph API')
        results = requests.get(resource, headers=requestHeaders).json()

        # If there's more data
        while "@odata.nextLink" in results:
            next_response = requests.get(results["@odata.nextLink"], headers=requestHeaders)
            next_data = next_response.json()
            results["value"].extend(next_data["value"])
            if "@odata.nextLink" in next_data:
                results["@odata.nextLink"] = next_data["@odata.nextLink"]
            else:
                del results["@odata.nextLink"]

    except Exception as e:
        logging.critical(f"{traceback.format_exc()}")
    finally:
        return results

#Get all users from the active directory
def get_user_data():
    try:
        logging.warning('Authenticate microsoft azure active directory API')
        requestHeaders = msgraph_auth()
        users = msgraph_request(graphURI + '/v1.0/users', requestHeaders)
        if 'value' in users:
            return users
    except Exception as e:
        logging.critical(f"{traceback.format_exc()}")
        return {}

#Get all active directory resource groups function                     
def get_group_data():
    try:
        logging.warning('Authenticate microsoft azure active directory API')
        requestHeaders = msgraph_auth()
        groups = msgraph_request(graphURI + '/v1.0/groups', requestHeaders)
        if 'value' in groups:
            return groups
    except Exception as e:
        logging.critical(f"{traceback.format_exc()}")
        return {}


#Get all active directory applications function
def get_app_data():
    try:
        logging.warning('Authenticate microsoft azure active directory API')
        apps = {}
        requestHeaders = msgraph_auth()
        apps = msgraph_request(graphURI + f'/v1.0/applications',requestHeaders)
        if 'value' in apps:
            return apps
    except Exception as e:
        logging.critical(f"{traceback.format_exc()}")
        return {}
