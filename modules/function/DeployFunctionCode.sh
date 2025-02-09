#!/usr/bin/env bash
set -euo pipefail

# rm -f "${ZIP_FILE_PATH}" || true
# wget --tries=5 --timeout=30 --continue --server-response "${ZIP_BLOB_URL}" -O "${ZIP_FILE_PATH}"
# curl -o ${ZIP_FILE_PATH} -L --fail --retry 2 --retry-delay 4 "${ZIP_BLOB_URL}"

# echo "FUNCTION_APP_NAME: ${FUNCTION_APP_NAME}"
# echo "RESOURCE_GROUP: ${RESOURCE_GROUP}"
# echo "SUBSCRIPTION_ID: ${SUBSCRIPTION_ID}"
# echo "ZIP_FILE_PATH: ${ZIP_FILE_PATH}"


az functionapp deployment source config-zip \
    --name "${FUNCTION_APP_NAME}" \
    --resource-group "${RESOURCE_GROUP}" \
    --subscription "${SUBSCRIPTION_ID}" \
    --src "${ZIP_FILE_PATH}" \
    --build-remote true

    # curl -X POST -u <deployment_user> --data-binary "@<zip_file_path>" https://<app_name>.scm.azurewebsites.net/api/zipdeploy

# WORKING_DIR="cyngular_func_dir"
# unzip -o "${ZIP_FILE_PATH}" -d "${WORKING_DIR}"

# pushd "${WORKING_DIR}"
# func azure functionapp publish "${FUNCTION_APP_NAME}" \
#     --subscription "${SUBSCRIPTION_ID}" \
#     --build remote --python
# popd
