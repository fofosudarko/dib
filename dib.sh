#!/bin/bash
#
# File: dib.sh -> Build, push docker images to a registry and/or deploy to a Kubernetes cluster
#
# (c) 2021 Frederick Ofosu-Darko <fofosudarko@gmail.com>
#
# Usage: bash dib.sh DIB_RUN_COMMAND <MORE_COMMANDS>
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
  source "$LIB_DIR/file.sh"
}

function load_rc_file() {
  source "$LIB_DIR/rc_path.sh"

  [[ ! -f "$DIB_RC_FILE" ]] && : || import_envvars_from_rc_file "$DIB_RC_FILE"
}

function deploy_to_k8s_cluster() {
  if ! deploy_to_kubernetes_cluster 
  then
    msg 'Kubernetes manifests deployed unsuccessfully'
  fi
}

load_system_commands
load_common_functions

COMMAND="$0"

if [[ "$#" -lt 1 ]]
then
  show_help
  exit 0
fi

DIB_RUN_COMMAND="${1:-build}"
shift

DIB_HOME=${DIB_HOME/\~/$HOME}
DIB_APP_BUILD_SRC=${DIB_APP_BUILD_SRC:-''}
DIB_APP_IMAGE_TAG=
DIB_FILE_TYPE=
DIB_FILE_RESOURCE=
DIB_ENV_TYPE=
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
   [[ "$DIB_RUN_COMMAND" == "deploy" ]] || \
   [[ "$DIB_RUN_COMMAND" == "generate" ]]
then
  if [[ "$#" -ge 2 ]] 
  then
    DIB_APP_IMAGE="$1"
    DIB_APP_IMAGE_TAG="$2"
  fi
elif [[ "$DIB_RUN_COMMAND" == "edit" || "$DIB_RUN_COMMAND" == "show" || "$DIB_RUN_COMMAND" == "path" ]]
then
  if [[ "$#" -ge 3 ]]
  then
    DIB_APP_IMAGE="$1"
    DIB_FILE_TYPE="$2"
    DIB_FILE_RESOURCE="$3"
  fi
elif [[ "$DIB_RUN_COMMAND" == "env" ]]
then
  [[ "$#" -ge 1 ]] && DIB_ENV_TYPE="$1"
elif [[ "$DIB_RUN_COMMAND" == "edit-deploy" ]]
then
  if [[ "$#" -ge 4 ]]
  then
    DIB_APP_IMAGE="$1"
    DIB_FILE_TYPE="$2"
    DIB_FILE_RESOURCE="$3"
    DIB_APP_IMAGE_TAG="$4"
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

load_rc_file
load_variables
load_more_functions

check_app_framework_validity
check_app_environment_validity
create_default_directories_if_not_exist

case "$DIB_RUN_COMMAND"
in
  build|build-push|build-push-deploy)
    copy_docker_project "$DOCKER_APP_BUILD_SRC" "$DOCKER_APP_BUILD_DEST"
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
  deploy_to_k8s_cluster
elif [[ "$DIB_RUN_COMMAND" == "push" ]]
then
  push_docker_image
elif [[ "$DIB_RUN_COMMAND" == "deploy" ]]
then
  deploy_to_k8s_cluster
elif [[ "$DIB_RUN_COMMAND" == "generate" ]]
then
  if generate_kubernetes_manifests
  then
    msg "The kubernetes manifests can be found here: $DOCKER_APP_COMPOSE_K8S_DIR"
  fi
elif [[ "$DIB_RUN_COMMAND" == "edit" ]]
then
  parse_edit_command "$DIB_FILE_TYPE" "$DIB_FILE_RESOURCE"
elif [[ "$DIB_RUN_COMMAND" == "show" ]]
then
  parse_show_command "$DIB_FILE_TYPE" "$DIB_FILE_RESOURCE"
elif [[ "$DIB_RUN_COMMAND" == "path" ]]
then
  parse_path_command "$DIB_FILE_TYPE" "$DIB_FILE_RESOURCE"
elif [[ "$DIB_RUN_COMMAND" == "env" ]]
then
  [[ -z "$DIB_ENV_TYPE" ]] && get_all_envvars || parse_env_command "$DIB_ENV_TYPE"
elif [[ "$DIB_RUN_COMMAND" == "edit-deploy" ]]
then
  parse_edit_command "$DIB_FILE_TYPE" "$DIB_FILE_RESOURCE"
else
  msg "Run command '$DIB_RUN_COMMAND' unknown"
  exit 1
fi

exit 0

## -- finish