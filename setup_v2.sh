#!/bin/bash
# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Run ./setup.sh from a project with a billing account enabled
# This will create a single project.


pushd $(dirname "$0") > /dev/null


function prompt_project_id () {
    PROJECT_ID_DEFAULT="${USER}-emblem-${1}"

    read -p $"Please enter the $(tput setaf 1)$(tput bold)$1$(tput sgr0) project ID: [${PROJECT_ID_DEFAULT}]   " PROJECT_ID
    PROJECT_ID="${PROJECT_ID:-${PROJECT_ID_DEFAULT}}"

    PROJECT_NAME=$(gcloud projects describe ${PROJECT_ID} | grep name | cut -d' ' -f 2-)
}

function execute_terraform () {
    # Specify project IDs for Terraform to use
    export TF_VAR_google_app_project_id="$1"
    export TF_VAR_google_ops_project_id="$2"

    # Create terraform workspace, if it doesn't yet exist
    if [ -n "$3" ]; then
        terraform workspace new "$3" || terraform workspace select "$3"
    fi

    # Perform terraform steps
    terraform init
    terraform apply --auto-approve
}


# Copy /client-libs folder into /website/client-libs
cp -r client-libs/ website/client-libs/


########################
# Record project names #
########################
prompt_project_id "ops"
OPS_PROJECT="${PROJECT_NAME}"

prompt_project_id "prod"
PROD_PROJECT="${PROJECT_NAME}"

prompt_project_id "stage"
STAGE_PROJECT="${PROJECT_NAME}"


###########################
# Terraform - ops project #
###########################
pushd terraform/ops > /dev/null
execute_terraform $STAGE_PROJECT $OPS_PROJECT
popd > /dev/null


##################################
# Terraform - production project #
##################################
export TF_VAR_release_type="prod"

pushd terraform/deployment > /dev/null
execute_terraform $PROD_PROJECT $OPS_PROJECT "prod"
popd > /dev/null


###############################
# Terraform - staging project #
###############################
export TF_VAR_release_type="stage"

pushd terraform/deployment > /dev/null
execute_terraform $STAGE_PROJECT $OPS_PROJECT "stage"
popd > /dev/null


###################
# Deploy Services #
###################

# Make sure website has all dependencies
# (including a copy of the client-libs/ folder)
pushd website > /dev/null
pip install -r requirements.txt
popd > /dev/null

# Submit remote builds
gcloud builds submit --config=setup.cloudbuild.yaml \
--substitutions="_DIR=website,_STAGING_PROJECT=${STAGE_PROJECT},_PROD_PROJECT=${PROD_PROJECT}" \
--project="${OPS_PROJECT}"

gcloud builds submit --config=setup.cloudbuild.yaml \
--substitutions="_DIR=content-api,_STAGING_PROJECT=${STAGE_PROJECT},_PROD_PROJECT=${PROD_PROJECT}" \
--project="${OPS_PROJECT}"


################
# Set up CI/CD #
################

REPO_CONNECT_URL="https://console.cloud.google.com/cloud-build/triggers/connect?\
project=${OPS_PROJECT}"
echo "Connect your repos: ${REPO_CONNECT_URL}"
python3 -m webbrowser ${REPO_CONNECT_URL}

read -p "Once your repo is connected, please continue by typing any key."

continue=1
while [[ ${continue} -gt 0 ]]
do

read -p "Please input the repo-owner [GoogleCloudPlatform]: " repo_owner
repo_owner=${name:-GoogleCloudPlatform}
read -p "Please input the repo name [emblem]: " repo_name
repo_name=${name:-emblem}

read -p "Is this the correct repo: ${repo_owner}/${repo_name}? (y/n) " yesno

if [[ ${yesno} == "y" ]]
then continue=0
fi

done

###################
# Create Triggers #
###################

pushd terraform/build_triggers > /dev/null
execute_terraform $STAGE_PROJECT $OPS_PROJECT
popd > /dev/null