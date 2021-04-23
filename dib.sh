#!/bin/bash
#
# File: dib.sh -> Build, push docker images to a registry and/or deploy to a Kubernetes cluster
#
# Usage: bash dib.sh DIB_RUN_COMMAND <MORE_COMMANDS>
#
#

## - start here

set -eu

: ${SCRIPT_DIR=$(dirname $(realpath ${BASH_SOURCE[0]}))}
: ${LIB_DIR="${SCRIPT_DIR}/lib"}

function load_init_functions() {
  source "$LIB_DIR/functions/help.sh"
  source "$LIB_DIR/functions/cache.sh"
  source "$LIB_DIR/functions/common.sh"
  source "$LIB_DIR/functions/executors.sh"
  source "$LIB_DIR/functions/database.sh"
}

function load_commands_data() {  
  source "$LIB_DIR/data/commands.sh"
}

function load_paths_data() {  
  source "$LIB_DIR/data/paths.sh"
}

function load_init_data() {  
  source "$LIB_DIR/data/init.sh"
}

function load_core_data() {  
  source "$LIB_DIR/data/core.sh"
}

function load_template_data() {  
  source "$LIB_DIR/data/template.sh"
}

function load_more_functions() {
  source "$LIB_DIR/functions/file.sh"
  source "$LIB_DIR/functions/spring.sh"
  source "$LIB_DIR/functions/docker.sh"
  source "$LIB_DIR/functions/kubernetes.sh"
}

load_commands_data
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
DIB_APP_BUILD_SRC=
DIB_APP_BUILD_DEST=
DIB_APP_PROJECT=
DIB_APP_FRAMEWORK=
DIB_APP_ENVIRONMENT=
DIB_APP_IMAGE=
DIB_APP_IMAGE_TAG=
DIB_APP_FILE_TYPE=
DIB_APP_FILE_RESOURCE=
DIB_APP_ENV_TYPE=
DIB_APP_IMAGE_NEW=
DIB_APP_SRC_ENV=
DIB_APP_DEST_ENV=
DIB_DOCKER_COMPOSE_FILE_CHANGED=0
DIB_K8S_RESOURCES_ANNOTATIONS_FILES_CHANGED=0
DIB_APP_ENV_FILE_CHANGED=0
DIB_APP_COMMON_ENV_FILE_CHANGED=0
DIB_APP_PROJECT_ENV_FILE_CHANGED=0
DIB_APP_SERVICE_ENV_FILE_CHANGED=0

KUBECONFIG=

load_init_data

case "$DIB_RUN_COMMAND"
in
  init) execute_init_command;;
  goto) execute_goto_command "$@";;
  doctor) execute_doctor_command;;
  get:key) execute_get_key_command "$@";;
  get:project) execute_get_project_command "$@";;
  get:all) execute_get_all_command;;
  version|--version|-v) execute_version_command;;
  help|--help|-h) execute_help_command;;
  copy) execute_copy_command "$@";;
  cache) execute_cache_command;;
  reset) execute_reset_command;;
  switch) execute_switch_command "$@";;
  build) execute_build_command "$@";;
  build:push) execute_build_push_command "$@";;
  build:push:deploy) execute_build_push_deploy_command "$@";;
  build:run) execute_build_run_command "$@";;
  push) execute_push_command "$@";;
  deploy) execute_deploy_command "$@";;
  generate) execute_generate_command "$@";;
  run) execute_run_command;;
  stop) execute_stop_command;;
  edit) execute_edit_command "$@";;
  show) execute_show_command "$@";;
  ps) execute_ps_command;;
  path) execute_path_command "$@";;
  erase) execute_erase_command "$@";;
  restore) execute_restore_command "$@";;
  view) execute_view_command "$@";;
  env) execute_env_command "$@";;
  edit:deploy) execute_edit_deploy_command "$@";;
  copy:env) execute_copy_env_command "$@";;
  copy:env:new) execute_copy_env_new_command "$@";;
  *)
    msg "Run command '$DIB_RUN_COMMAND' unknown."
    exit 1
  ;;
esac

remove_tmp_file

exit 0

## -- finish