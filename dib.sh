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

function load_init_functions() {  
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
  source "$LIB_DIR/spring.sh"
  source "$LIB_DIR/docker.sh"
  source "$LIB_DIR/kubernetes.sh"
}

function load_cache_file() {
  if [[ -f "$DIB_APP_CACHE_FILE" ]]
  then
    source_envvars_from_file "$DIB_APP_CACHE_FILE"
  else
    :
  fi
}

function load_root_cache_file() {
  if [[ -z "$DIB_APP_KEY" ]]
  then
    msg "Please provide DIB_APP_KEY and try again."
    exit 1
  fi

  format_root_cache_file

  if [[ -f "$DIB_APP_ROOT_CACHE_FILE" ]]
  then
    source_envvars_from_file "$DIB_APP_ROOT_CACHE_FILE"
  else
    :
  fi
}

load_commands
load_init_functions

if [[ "$#" -lt 1 ]]
then
  execute_help_command
fi

DIB_RUN_COMMAND="${1:-build}"
shift

DIB_HOME=${DIB_HOME/\~/$HOME}
DIB_APP_KEY=${DIB_APP_KEY:-''}
USER_DIB_APP_BUILD_SRC=
USER_DIB_APP_BUILD_DEST=
USER_DIB_APP_PROJECT=
USER_DIB_APP_FRAMEWORK=
USER_DIB_APP_ENVIRONMENT=
USER_DIB_APP_IMAGE=
USER_DIB_APP_IMAGE_TAG=
USER_DIB_APP_PORTS=
USER_DIB_APP_ENV_FILES=
USER_DIB_APP_GET_VALUE=
DIB_APP_BUILD_SRC=
DIB_APP_BUILD_DEST=
DIB_APP_PROJECT=
DIB_APP_FRAMEWORK=
DIB_APP_ENVIRONMENT=
DIB_APP_IMAGE=
DIB_APP_IMAGE_TAG=
DIB_APP_PORTS=
DIB_APP_ENV_FILES=
DIB_FILE_TYPE=
DIB_FILE_RESOURCE=
DIB_ENV_TYPE=
DIB_DOCKER_COMPOSE_FILE_CHANGED=0
DIB_K8S_RESOURCES_ANNOTATIONS_FILES_CHANGED=0
DIB_APP_ENV_FILE_CHANGED=0
DIB_APP_COMMON_ENV_FILE_CHANGED=0
DIB_APP_PROJECT_ENV_FILE_CHANGED=0
DIB_APP_SERVICE_ENV_FILE_CHANGED=0
DIB_APP_CONTAINERS_RESTART=0

KUBECONFIG=

load_init

if [[ "$DIB_RUN_COMMAND" == "goto" ]]
then
  if [[ "$#" -ge 3 ]]
  then
    USER_DIB_APP_FRAMEWORK="$1"
    USER_DIB_APP_PROJECT="$2"
    USER_DIB_APP_IMAGE="$3"
  elif [[ "$#" -ge 2 ]]
  then
    USER_DIB_APP_FRAMEWORK="$1"
    USER_DIB_APP_IMAGE="$2"
    USER_DIB_APP_PROJECT="$USER_DIB_APP_IMAGE"
  fi

  update_core_variables_if_changed
  execute_goto_command
elif [[ "$DIB_RUN_COMMAND" == "help" ]]
then
  execute_help_command
elif [[ "$DIB_RUN_COMMAND" == "doctor" ]]
then
  execute_doctor_command
elif [[ "$DIB_RUN_COMMAND" == "get-key" ]]
then
  if [[ "$#" -ge 1 ]]
  then
    USER_DIB_APP_GET_VALUE="$1"
  fi

  execute_get_key_command "$USER_DIB_APP_GET_VALUE"
elif [[ "$DIB_RUN_COMMAND" == "get-project" ]]
then
  if [[ "$#" -ge 1 ]]
  then
    USER_DIB_APP_GET_VALUE="$1"
  fi

  execute_get_project_command "$USER_DIB_APP_GET_VALUE"
elif [[ "$DIB_RUN_COMMAND" == "version" ]]
then
  execute_version_command
fi

if [[ "$DIB_RUN_COMMAND" == "build" ]] || \
   [[ "$DIB_RUN_COMMAND" == "build-push" ]] || \
   [[ "$DIB_RUN_COMMAND" == "build-push-deploy" ]] || \
   [[ "$DIB_RUN_COMMAND" == "push" ]] || \
   [[ "$DIB_RUN_COMMAND" == "deploy" ]] || \
   [[ "$DIB_RUN_COMMAND" == "generate" ]]
then
  if [[ "$#" -ge 2 ]] 
  then
    USER_DIB_APP_IMAGE="$1"
    USER_DIB_APP_IMAGE_TAG="$2"
  fi
elif [[ "$DIB_RUN_COMMAND" == "edit" ]] || \
     [[ "$DIB_RUN_COMMAND" == "show" ]] || \
     [[ "$DIB_RUN_COMMAND" == "path" ]] || \
     [[ "$DIB_RUN_COMMAND" == "restore" ]] || \
     [[ "$DIB_RUN_COMMAND" == "erase" ]]
then
  if [[ "$#" -ge 3 ]]
  then
    USER_DIB_APP_IMAGE="$1"
    DIB_FILE_TYPE="$2"
    DIB_FILE_RESOURCE="$3"
  elif [[ "$#" -ge 2 ]]
  then
    USER_DIB_APP_IMAGE="$1"
    DIB_FILE_TYPE="$2"
  fi
elif [[ "$DIB_RUN_COMMAND" == "env" ]]
then
  [[ "$#" -ge 1 ]] && DIB_ENV_TYPE="$1"
elif [[ "$DIB_RUN_COMMAND" == "edit-deploy" ]]
then
  if [[ "$#" -ge 4 ]]
  then
    USER_DIB_APP_IMAGE="$1"
    DIB_FILE_TYPE="$2"
    DIB_FILE_RESOURCE="$3"
    USER_DIB_APP_IMAGE_TAG="$4"
  fi
elif [[ "$DIB_RUN_COMMAND" == "init" ]]
then
  execute_init_command
elif [[ "$DIB_RUN_COMMAND" == "switch" ]]
then
  if [[ "$#" -ge 2 ]]
  then
    USER_DIB_APP_IMAGE="$1"
    USER_DIB_APP_ENVIRONMENT="$2"
  fi
elif [[ "$DIB_RUN_COMMAND" == "copy" ]]
then
  if [[ "$#" -ge 2 ]]
  then
    USER_DIB_APP_IMAGE="$1"
    USER_DIB_APP_BUILD_SRC="$2"
  fi
elif [[ "$DIB_RUN_COMMAND" == "run" ]]
then
  if [[ "$#" -ge 2 ]]
  then
    USER_DIB_APP_IMAGE="$1"
    USER_DIB_APP_PORTS="$2"
    USER_DIB_APP_ENV_FILES="$3"
  fi
fi

load_root_cache_file
update_core_variables_if_changed
load_core
update_other_variables_if_changed

if [[ "$DIB_RUN_COMMAND" == "copy" ]]
then
  execute_copy_command
elif [[ "$DIB_RUN_COMMAND" == "cache" ]]
then
  execute_cache_command
elif [[ "$DIB_RUN_COMMAND" == "reset" ]]
then
  execute_reset_command
elif [[ "$DIB_RUN_COMMAND" == "switch" ]]
then
  execute_switch_command
fi

load_paths
load_cache_file
load_template
load_more_functions

if [[ "$DIB_RUN_COMMAND" == "build" ]]
then
  execute_build_command
elif [[ "$DIB_RUN_COMMAND" == "build-push" ]]
then
  execute_build_and_push_command
elif [[ "$DIB_RUN_COMMAND" == "build-push-deploy" ]]
then
  execute_build_push_and_deploy_command
elif [[ "$DIB_RUN_COMMAND" == "push" ]]
then
  execute_push_command
elif [[ "$DIB_RUN_COMMAND" == "deploy" ]]
then
  execute_deploy_command
elif [[ "$DIB_RUN_COMMAND" == "run" ]]
then
  execute_run_command
elif [[ "$DIB_RUN_COMMAND" == "stop" ]]
then
  execute_stop_command
elif [[ "$DIB_RUN_COMMAND" == "ps" ]]
then
  execute_ps_command
elif [[ "$DIB_RUN_COMMAND" == "generate" ]]
then
  execute_generate_command
elif [[ "$DIB_RUN_COMMAND" == "edit" ]]
then
  execute_edit_command "$DIB_FILE_TYPE" "$DIB_FILE_RESOURCE"
elif [[ "$DIB_RUN_COMMAND" == "show" ]]
then
  execute_show_command "$DIB_FILE_TYPE" "$DIB_FILE_RESOURCE"
elif [[ "$DIB_RUN_COMMAND" == "path" ]]
then
  execute_path_command "$DIB_FILE_TYPE" "$DIB_FILE_RESOURCE"
elif [[ "$DIB_RUN_COMMAND" == "erase" ]]
then
  execute_erase_command "$DIB_FILE_TYPE" "$DIB_FILE_RESOURCE"
elif [[ "$DIB_RUN_COMMAND" == "restore" ]]
then
  execute_restore_command "$DIB_FILE_TYPE" "$DIB_FILE_RESOURCE"
elif [[ "$DIB_RUN_COMMAND" == "env" ]]
then
  if [[ -z "$DIB_ENV_TYPE" ]]
  then
    get_all_envvars
  else
    execute_env_command "$DIB_ENV_TYPE"
  fi
elif [[ "$DIB_RUN_COMMAND" == "edit-deploy" ]]
then
  msg 'Oops, not implemented yet.'
else
  msg "Run command '$DIB_RUN_COMMAND' unknown."
  exit 1
fi

exit 0

## -- finish