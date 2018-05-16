#!/bin/sh
# ------------------------------------------------------------------------
# Copyright 2018 WSO2, Inc. (http://wso2.com)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License
# ------------------------------------------------------------------------
set -e

# product profile variable
wso2_server_profile=worker

# custom WSO2 non-root user and group variables
user=wso2carbon
group=wso2

# file path variables
volumes=${WORKING_DIRECTORY}/volumes
k8s_volumes=${WORKING_DIRECTORY}/kubernetes-volumes

# check if the WSO2 non-root user home exists
test ! -d ${WORKING_DIRECTORY} && echo "WSO2 Docker non-root user home does not exist" && exit 1

# check if the WSO2 product home exists
test ! -d ${WSO2_SERVER_HOME} && echo "WSO2 Docker product home does not exist" && exit 1

# copy configuration changes and external libraries

# check if any changed configuration files have been mounted
# if any file changes have been mounted, copy the WSO2 configuration files recursively
test -d ${volumes} && cp -r ${volumes}/* ${WSO2_SERVER_HOME}/

# check if a ConfigMap volume containing WSO2 worker configuration files has been mounted
if test -d ${k8s_volumes}/${WSO2_SERVER_PROFILE}/conf; then
    cp -rL ${k8s_volumes}/${WSO2_SERVER_PROFILE}/conf/* ${WSO2_SERVER_HOME}/conf/worker
fi

server_conf=${WSO2_SERVER_HOME}/conf/${WSO2_SERVER_PROFILE}

# update node ip
export local_docker_ip=$(ip route get 1 | awk '{print $NF;exit}')
deployment_yaml_location=${server_conf}/deployment.yaml
if [[ ! -z ${local_docker_ip} ]]; then
   sed -i "s#wso2-sp#wso2-sp${local_docker_ip}#" "${deployment_yaml_location}"
   sed -i "s#NODE_IP#${local_docker_ip}#" "${deployment_yaml_location}"
   if [[ $? == 0 ]]; then
      echo "Successfully updated node with ${local_docker_ip}"
   else
      echo "Error occurred while updating node with ${local_docker_ip}"
   fi
fi

# start the WSO2 Carbon server profile
sh ${WSO2_SERVER_HOME}/bin/worker.sh
