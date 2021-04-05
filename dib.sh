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
  test -f "$LIB_DIR/common.sh" && source "$LIB_DIR/common.sh"
}

function load_vars() {  
  test -f "$LIB_DIR/vars.sh" && source "$LIB_DIR/vars.sh"
}

function load_all_functions() {  
  test -f "$LIB_DIR/springboot.sh" && source "$LIB_DIR/springboot.sh"
  test -f "$LIB_DIR/docker.sh"  && source "$LIB_DIR/docker.sh"
  test -f "$LIB_DIR/kubernetes.sh" && source "$LIB_DIR/kubernetes.sh"
}

load_common_functions

COMMAND="$0"

#if [[ "$#" -ne 6 ]]
#then
#  msg 'expects 5 arguments i.e. DIB_RUN_COMMAND CI_JOB APP_PROJECT APP_FRAMEWORK APP_IMAGE'
#  exit 1
#fi

DIB_RUN_COMMAND="${1:-build}"
DIB_CI_JOB="$2"
DIB_APP_PROJECT="$3"
DIB_APP_ENVIRONMENT="$4"
DIB_APP_FRAMEWORK="$5"
DIB_APP_IMAGE="$6"

load_vars
#load_all_functions

KUBECONFIG=
DOCKER_COMPOSE_FILE_CHANGED=0
K8S_RESOURCES_ANNOTATIONS_FILES_CHANGED=0
APP_ENV_FILE_CHANGED=0
APP_COMMON_ENV_FILE_CHANGED=0
APP_PROJECT_ENV_FILE_CHANGED=0
APP_SERVICE_ENV_FILE_CHANGED=0

# check kompose version

if ! is_kompose_version_valid
then
  msg "Invalid kompose command version. Please upgrade to a version greater than 1.20.x"
  exit 1
fi

# check passed Run command

#if ! echo -ne "$DIB_RUN_COMMAND"| grep -qE "$DIB_RUN_COMMANDS"
#then
#  msg "Run command must be in $DIB_RUN_COMMANDS"
#  exit 1
#fi

# check passed app environment

#if ! echo -ne "$APP_ENVIRONMENT"| grep -qE "$DIB_APP_ENVIRONMENTS"
#then
#  msg "App environment must be in $DIB_APP_ENVIRONMENTS"
#  exit 1
#fi

#create_default_directories_if_not_exist

#copy_docker_project "$DOCKER_APP_BUILD_SRC" "$(dirname $DOCKER_APP_BUILD_DEST)"

#copy_docker_build_files "$DOCKER_APP_BUILD_FILES" "$DOCKER_APP_BUILD_DEST"

#case "$APP_FRAMEWORK"
#in
#  springboot)
#    run_as "$DOCKER_USER" "
#      [[ -d $SPRINGBOOT_APPLICATION_PROPERTIES_DIR ]] || mkdir -p $SPRINGBOOT_APPLICATION_PROPERTIES_DIR
#      cp $SPRINGBOOT_BASE_APPLICATION_PROPERTIES $SPRINGBOOT_APPLICATION_PROPERTIES_DIR
#      cp $SPRINGBOOT_APPLICATION_PROPERTIES $SPRINGBOOT_APPLICATION_PROPERTIES_DIR
#    "
#  ;;
#  angular|react|flask|express|mux|feathers)
#    run_as "$DOCKER_USER" "rsync -av $DOCKER_APP_CONFIG_DIR/ $DOCKER_APP_BUILD_DEST"
#  ;;
#  nuxt|next)
#    set_app_frontend_build_mode || exit 1
#  ;;
#  *)
#    msg "app framework '$APP_FRAMEWORK' unknown"
#    exit 1
#  ;;
#esac

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
elif [[ "$DIB_RUN_COMMAND" == "doctor" ]]
then
  check_app_dependencies
else
  msg 'no Run command specified'
  exit 1
fi

exit 0

## -- finish