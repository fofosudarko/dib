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

function load_commands() {  
  source "$LIB_DIR/data/commands.sh"
}

function load_paths() {  
  source "$LIB_DIR/data/paths.sh"
}

function load_init() {  
  source "$LIB_DIR/data/init.sh"
}

function load_core() {  
  source "$LIB_DIR/data/core.sh"
}

function load_template() {  
  source "$LIB_DIR/data/template.sh"
}

function load_more_functions() {
  source "$LIB_DIR/file.sh"
  source "$LIB_DIR/springboot.sh"
  source "$LIB_DIR/docker.sh"
  source "$LIB_DIR/kubernetes.sh"
}

function load_cache_file() {
  if [[ -f "$DIB_APP_CACHE_FILE" ]]
  then
    import_envvars_from_cache_file "$DIB_APP_CACHE_FILE"
  else
    :
  fi
}

function load_root_cache_file() {
  if [[ -f "$DIB_APP_ROOT_CACHE_FILE" ]]
  then
    import_envvars_from_cache_file "$DIB_APP_ROOT_CACHE_FILE"
  else
    :
  fi
}

function deploy_to_k8s_cluster() {
  if ! deploy_to_kubernetes_cluster 
  then
    msg 'Kubernetes manifests deployed unsuccessfully'
  fi
}

load_commands
load_common_functions

if [[ "$#" -lt 1 ]]
then
  show_help
  exit 0
fi

DIB_RUN_COMMAND="${1:-build}"
shift

DIB_HOME=${DIB_HOME/\~/$HOME}
DIB_APP_BUILD_SRC=
DIB_APP_BUILD_DEST=
DIB_APP_PROJECT=
DIB_APP_FRAMEWORK=
DIB_APP_ENVIRONMENT=
DIB_APP_IMAGE=
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

load_init
load_root_cache_file

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
elif [[ "$DIB_RUN_COMMAND" == "edit" ]] || \
     [[ "$DIB_RUN_COMMAND" == "show" ]] || \
     [[ "$DIB_RUN_COMMAND" == "path" ]]
then
  if [[ "$#" -ge 3 ]]
  then
    DIB_APP_IMAGE="$1"
    DIB_FILE_TYPE="$2"
    DIB_FILE_RESOURCE="$3"
  elif [[ "$#" -ge 2 ]]
  then
    DIB_APP_IMAGE="$1"
    DIB_FILE_TYPE="$2"
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
elif [[ "$DIB_RUN_COMMAND" == "init" ]]
then
  parse_init_command
elif [[ "$DIB_RUN_COMMAND" == "go" ]]
then
  if [[ "$#" -ge 3 ]]
  then
    DIB_APP_FRAMEWORK="$1"
    DIB_APP_PROJECT="$2"
    DIB_APP_IMAGE="$3"
  elif [[ "$#" -ge 2 ]]
  then
    DIB_APP_FRAMEWORK="$1"
    DIB_APP_IMAGE="$2"
    DIB_APP_PROJECT="$DIB_APP_IMAGE"
  fi

  parse_go_command
elif [[ "$DIB_RUN_COMMAND" == "checkout" ]]
then
  if [[ "$#" -ge 2 ]]
  then
    DIB_APP_IMAGE="$1"
    DIB_APP_ENVIRONMENT="$2"
  fi

  parse_checkout_command
elif [[ "$DIB_RUN_COMMAND" == "copy" ]]
then
  if [[ "$#" -ge 2 ]]
  then
    DIB_APP_IMAGE="$1"
    DIB_APP_BUILD_SRC="$2"
  fi

  parse_copy_command
elif [[ "$DIB_RUN_COMMAND" == "status" ]]
then
  parse_status_command
elif [[ "$DIB_RUN_COMMAND" == "help" ]]
then
  show_help
elif [[ "$DIB_RUN_COMMAND" == "doctor" ]]
then
  check_app_dependencies
fi

load_core
load_paths
load_cache_file
load_template
load_more_functions

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
    msg "The kubernetes manifests can be found here: $DIB_APP_COMPOSE_K8S_DIR"
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
  if [[ -z "$DIB_ENV_TYPE" ]]
  then
    get_all_envvars
  else
    parse_env_command "$DIB_ENV_TYPE"
  fi
elif [[ "$DIB_RUN_COMMAND" == "edit-deploy" ]]
then
  parse_edit_command "$DIB_FILE_TYPE" "$DIB_FILE_RESOURCE"
else
  msg "Run command '$DIB_RUN_COMMAND' unknown"
  exit 1
fi

exit 0

## -- finish