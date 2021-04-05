#!/bin/bash
#
# File: dib.sh -> Build, push docker images to a registry and/or deploy to a Kubernetes cluster
#
# (c) 2021 Frederick Ofosu-Darko <fofosudarko@gmail.com>
#
# Usage: bash dib.sh DIB_RUN_COMMAND CI_JOB APP_PROJECT APP_ENVIRONMENT APP_FRAMEWORK APP_IMAGE 
#   ENV_VARS: APP_IMAGE_TAG APP_KUBERNETES_NAMESPACE APP_DB_CONNECTION_POOL
#             APP_KUBERNETES_CONTEXT APP_BUILD_MODE APP_NPM_RUN_COMMANDS KUBECONFIGS
#             KUBERNETES_SERVICE_LABEL USE_GIT_COMMIT USE_BUILD_DATE
#
#

## - start here

set -eu

: ${SCRIPT_DIR=$(dirname $(realpath ${BASH_SOURCE[0]}))}
: ${LIB_DIR="${SCRIPT_DIR}/lib"}

function load_common_functions() {  
  source "$LIB_DIR/common.sh"
}

function load_system_commands() {  
  source "$LIB_DIR/system_commands.sh"
}

function load_variables() {  
  source "$LIB_DIR/variables.sh"
}

function load_more_functions() {
  source "$LIB_DIR/springboot.sh"
  source "$LIB_DIR/docker.sh"
  source "$LIB_DIR/kubernetes.sh"
  source "$LIB_DIR/editor.sh"
}

load_system_commands
load_common_functions

COMMAND="$0"

if [[ "$#" -eq 0 ]]
then
  show_help
  exit 0
fi

if [[ "$#" -lt 1 ]]
then
  msg 'expects at least 1 arguments i.e. DIB_RUN_COMMAND'
  exit 1
fi

DIB_RUN_COMMAND="${1:-build}"
shift

if [[ "$#" -ge 1 ]]
then
  DIB_APP_IMAGE="$1"
  shift
fi

DIB_HOME=${DIB_HOME/\~/$HOME}
DIB_APP_IMAGE_TAG=
DIB_FILE_TYPE=
DIB_FILE_RESOURCE=
KUBECONFIG=
DOCKER_COMPOSE_FILE_CHANGED=0
K8S_RESOURCES_ANNOTATIONS_FILES_CHANGED=0
APP_ENV_FILE_CHANGED=0
APP_COMMON_ENV_FILE_CHANGED=0
APP_PROJECT_ENV_FILE_CHANGED=0
APP_SERVICE_ENV_FILE_CHANGED=0

if [[ "$DIB_RUN_COMMAND" == "build" ]] || \
   [[ "$DIB_RUN_COMMAND" == "build-push" ]] || \
   [[ "$DIB_RUN_COMMAND" == "build-push-deploy" ]] || \
   [[ "$DIB_RUN_COMMAND" == "push" ]] || \
   [[ "$DIB_RUN_COMMAND" == "deploy" ]]
then
  [[ "$#" -ge 1 ]] && DIB_APP_IMAGE_TAG="$1"
elif [[ "$DIB_RUN_COMMAND" == "edit" ]]
then
  if [[ "$#" -ge 2 ]]
  then
    DIB_FILE_TYPE="$1"
    DIB_FILE_RESOURCE="$2"
  fi
elif [[ "$DIB_RUN_COMMAND" == "edit-deploy" ]]
then
  if [[ "$#" -ge 3 ]]
  then
    DIB_FILE_TYPE="$1"
    DIB_FILE_RESOURCE="$2"
    DIB_APP_IMAGE_TAG="$3"
  fi
elif [[ "$DIB_RUN_COMMAND" == "help" ]]
then
  show_help
  exit 0
elif [[ "$DIB_RUN_COMMAND" == "doctor" ]]
then
  check_app_dependencies
  exit 0
fi

load_variables
load_more_functions
check_app_framework_validity
check_app_environment_validity
create_default_directories_if_not_exist

case "$DIB_RUN_COMMAND"
in
  build|build-push|build-push-deploy)
    copy_docker_project "$DOCKER_APP_BUILD_SRC" "$(dirname $DOCKER_APP_BUILD_DEST)"
    copy_docker_build_files "$DOCKER_APP_BUILD_FILES" "$DOCKER_APP_BUILD_DEST"
    copy_config_files "$DOCKER_APP_CONFIG_DIR" "$DOCKER_APP_BUILD_DEST"
  ;;
esac

if [[ "$DIB_RUN_COMMAND" == "build" ]]
then
  build_docker_image || abort_build_process
elif [[ "$DIB_RUN_COMMAND" == "build-push" ]]
then
  build_docker_image || abort_build_process
  push_docker_image
elif [[ "$DIB_RUN_COMMAND" == "build-push-deploy" ]]
then
  build_docker_image || abort_build_process
  push_docker_image
  deploy_to_kubernetes
elif [[ "$DIB_RUN_COMMAND" == "push" ]]
then
  push_docker_image
elif [[ "$DIB_RUN_COMMAND" == "deploy" ]]
then
  deploy_to_kubernetes
elif [[ "$DIB_RUN_COMMAND" == "edit" ]]
then
  parse_edit_command "$DIB_FILE_TYPE" "$DIB_FILE_RESOURCE"
elif [[ "$DIB_RUN_COMMAND" == "edit-deploy" ]]
then
  parse_edit_command "$DIB_FILE_TYPE" "$DIB_FILE_RESOURCE"
else
  msg "Run command '$DIB_RUN_COMMAND' unknown"
  exit 1
fi

exit 0

## -- finish