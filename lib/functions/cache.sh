#!/bin/bash
#
# File: cache.sh -> common cache operations
#
# Usage: source cache.sh
#
#

## - start here

function set_project_directories() {
  local directories=

  DIB_APP_CONFIG_DIR="$DIB_APPS_CONFIG_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$APP_ENVIRONMENT"
  DIB_APP_COMPOSE_DIR="$DIB_APPS_COMPOSE_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$APP_ENVIRONMENT"
  DIB_APP_COMPOSE_K8S_DIR="$DIB_APPS_COMPOSE_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$APP_ENVIRONMENT/kubernetes"
  DIB_APP_K8S_ANNOTATIONS_DIR="$DIB_APPS_K8S_ANNOTATIONS_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$APP_ENVIRONMENT"
  DIB_APP_PROJECT_ENV_DIR="$DIB_APPS_ENV_DIR/$APP_FRAMEWORK/$APP_PROJECT"
  DIB_APP_SERVICE_ENV_DIR="$DIB_APPS_ENV_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE"
  DIB_APP_COMMON_ENV_DIR="$DIB_APPS_ENV_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_ENVIRONMENT"
  DIB_APP_CACHE_DIR="$DIB_APPS_CACHE_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$APP_ENVIRONMENT"
  DIB_APP_RUN_DIR="$DIB_APPS_RUN_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$APP_ENVIRONMENT"
  DIB_APP_KEYSTORES_SRC="$DIB_APPS_KEYSTORES_DIR/$APP_PROJECT/$APP_ENVIRONMENT/keystores"
  DIB_APP_BUILD_DEST="$DIB_APPS_APPS_DIR/$APP_FRAMEWORK/$APP_IMAGE/$APP_ENVIRONMENT/$CI_JOB"
  DIB_APP_KEYSTORES_DEST="$DIB_APP_BUILD_DEST"

  directories="$DIB_APP_CONFIG_DIR $DIB_APP_COMPOSE_DIR $DIB_APP_COMPOSE_K8S_DIR"
  directories="$directories $DIB_APP_K8S_ANNOTATIONS_DIR $DIB_APP_PROJECT_ENV_DIR"
  directories="$directories $DIB_APP_SERVICE_ENV_DIR $DIB_APP_COMMON_ENV_DIR $DIB_APP_CACHE_DIR"
  directories="$directories $DIB_APP_RUN_DIR $DIB_APP_BUILD_DEST $DIB_APP_KEYSTORES_SRC"

  create_directories_if_not_exist "$directories"
}

function transfer_dirs_data_from_src_to_dest_env_on_copy_env() {
  
  function set_copy_env_directories() {
    
    [[ "$DIB_APP_SRC_ENV" == "$DIB_APP_DEST_ENV" ]] && return 1

    DIB_APP_CONFIG_DIR_SRC="$DIB_APPS_CONFIG_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$DIB_APP_SRC_ENV"
    DIB_APP_COMPOSE_DIR_SRC="$DIB_APPS_COMPOSE_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$DIB_APP_SRC_ENV"
    DIB_APP_K8S_ANNOTATIONS_DIR_SRC="$DIB_APPS_K8S_ANNOTATIONS_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$DIB_APP_SRC_ENV"
    DIB_APP_COMMON_ENV_DIR_SRC="$DIB_APPS_ENV_DIR/$APP_FRAMEWORK/$APP_PROJECT/$DIB_APP_SRC_ENV"
    DIB_APP_CACHE_DIR_SRC="$DIB_APPS_CACHE_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$DIB_APP_SRC_ENV"
    DIB_APP_RUN_DIR_SRC="$DIB_APPS_RUN_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$DIB_APP_SRC_ENV"

    DIB_APP_CONFIG_DIR_DEST="$DIB_APPS_CONFIG_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$DIB_APP_DEST_ENV"
    DIB_APP_COMPOSE_DIR_DEST="$DIB_APPS_COMPOSE_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$DIB_APP_DEST_ENV"
    DIB_APP_K8S_ANNOTATIONS_DIR_DEST="$DIB_APPS_K8S_ANNOTATIONS_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$DIB_APP_DEST_ENV"
    DIB_APP_COMMON_ENV_DIR_DEST="$DIB_APPS_ENV_DIR/$APP_FRAMEWORK/$APP_PROJECT/$DIB_APP_DEST_ENV"
    DIB_APP_CACHE_DIR_DEST="$DIB_APPS_CACHE_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$DIB_APP_DEST_ENV"
    DIB_APP_RUN_DIR_DEST="$DIB_APPS_RUN_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$DIB_APP_DEST_ENV"

    src_directories="$DIB_APP_CONFIG_DIR_SRC $DIB_APP_COMPOSE_DIR_SRC $DIB_APP_K8S_ANNOTATIONS_DIR_SRC"
    src_directories="$src_directories $DIB_APP_COMMON_ENV_DIR_SRC $DIB_APP_CACHE_DIR_SRC $DIB_APP_RUN_DIR_SRC"

    dest_directories="$DIB_APP_CONFIG_DIR_DEST $DIB_APP_COMPOSE_DIR_DEST $DIB_APP_K8S_ANNOTATIONS_DIR_DEST"
    dest_directories="$dest_directories $DIB_APP_COMMON_ENV_DIR_DEST $DIB_APP_CACHE_DIR_DEST $DIB_APP_RUN_DIR_DEST"

    create_directories_if_not_exist "$src_directories"
    create_directories_if_not_exist "$dest_directories"

    return 0
  }

  function copy_data_from_src_to_dest_directories() {
    local src_directories_list=($src_directories) dest_directories_list=($dest_directories)
    local src_directories_len="${#src_directories_list[@]}" dest_directories_len="${#dest_directories_list[@]}"

    [[ "$src_directories_len" -ne "$dest_directories_len" ]] && return 1

    local dir_index=0

    until [[ "$dir_index" == "$src_directories_len" ]]
    do
      msg "Copying data from ${src_directories_list[$dir_index]} to ${dest_directories_list[$dir_index]} ..."
      rsync -av ${src_directories_list[$dir_index]}/ ${dest_directories_list[$dir_index]}/
      dir_index=$((dir_index + 1))
    done

    return 0
  }

  local src_directories= dest_directories=

  DIB_APP_SRC_ENV="${DIB_APP_SRC_ENV:-$APP_ENVIRONMENT}"

  if [[ -n "$DIB_APP_SRC_ENV" && -n "$DIB_APP_DEST_ENV" ]]
  then
    set_copy_env_directories && copy_data_from_src_to_dest_directories
  fi
}

function transfer_dirs_data_from_src_to_dest_env_on_copy_env_new() {
  
  function set_copy_env_new_directories() {
    
    [[ "$APP_IMAGE" == "$DIB_APP_IMAGE_NEW" ]] && return 1

    DIB_APP_CONFIG_DIR_SRC="$DIB_APPS_CONFIG_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$DIB_APP_SRC_ENV"
    DIB_APP_COMPOSE_DIR_SRC="$DIB_APPS_COMPOSE_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$DIB_APP_SRC_ENV"
    DIB_APP_K8S_ANNOTATIONS_DIR_SRC="$DIB_APPS_K8S_ANNOTATIONS_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$DIB_APP_SRC_ENV"
    DIB_APP_CACHE_DIR_SRC="$DIB_APPS_CACHE_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$DIB_APP_SRC_ENV"
    DIB_APP_RUN_DIR_SRC="$DIB_APPS_RUN_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$DIB_APP_SRC_ENV"

    DIB_APP_CONFIG_DIR_DEST="$DIB_APPS_CONFIG_DIR/$APP_FRAMEWORK/$APP_PROJECT/$DIB_APP_IMAGE_NEW/$DIB_APP_DEST_ENV"
    DIB_APP_COMPOSE_DIR_DEST="$DIB_APPS_COMPOSE_DIR/$APP_FRAMEWORK/$APP_PROJECT/$DIB_APP_IMAGE_NEW/$DIB_APP_DEST_ENV"
    DIB_APP_K8S_ANNOTATIONS_DIR_DEST="$DIB_APPS_K8S_ANNOTATIONS_DIR/$APP_FRAMEWORK/$APP_PROJECT/$DIB_APP_IMAGE_NEW/$DIB_APP_DEST_ENV"
    DIB_APP_CACHE_DIR_DEST="$DIB_APPS_CACHE_DIR/$APP_FRAMEWORK/$APP_PROJECT/$DIB_APP_IMAGE_NEW/$DIB_APP_DEST_ENV"
    DIB_APP_RUN_DIR_DEST="$DIB_APPS_RUN_DIR/$APP_FRAMEWORK/$APP_PROJECT/$DIB_APP_IMAGE_NEW/$DIB_APP_DEST_ENV"

    src_directories="$DIB_APP_CONFIG_DIR_SRC $DIB_APP_COMPOSE_DIR_SRC $DIB_APP_K8S_ANNOTATIONS_DIR_SRC"
    src_directories="$src_directories $DIB_APP_CACHE_DIR_SRC $DIB_APP_RUN_DIR_SRC"

    dest_directories="$DIB_APP_CONFIG_DIR_DEST $DIB_APP_COMPOSE_DIR_DEST $DIB_APP_K8S_ANNOTATIONS_DIR_DEST"
    dest_directories="$dest_directories $DIB_APP_CACHE_DIR_DEST $DIB_APP_RUN_DIR_DEST"

    create_directories_if_not_exist "$src_directories"
    create_directories_if_not_exist "$dest_directories"

    return 0
  }

  function copy_data_from_src_to_dest_directories() {
    local src_directories_list=($src_directories) dest_directories_list=($dest_directories)
    local src_directories_len="${#src_directories_list[@]}" dest_directories_len="${#dest_directories_list[@]}"

    [[ "$src_directories_len" -ne "$dest_directories_len" ]] && return 1

    local dir_index=0

    until [[ "$dir_index" == "$src_directories_len" ]]
    do
      msg "Copying data from ${src_directories_list[$dir_index]} to ${dest_directories_list[$dir_index]} ..."
      rsync -av ${src_directories_list[$dir_index]}/ ${dest_directories_list[$dir_index]}/
      dir_index=$((dir_index + 1))
    done

    return 0
  }

  local src_directories= dest_directories=

  DIB_APP_SRC_ENV="${DIB_APP_SRC_ENV:-$APP_ENVIRONMENT}"
  DIB_APP_DEST_ENV="${DIB_APP_DEST_ENV:-$APP_ENVIRONMENT}"

  if [[ -n "$DIB_APP_SRC_ENV" && -n "$DIB_APP_DEST_ENV" && -n "$DIB_APP_IMAGE_NEW" ]]
  then
    set_copy_env_new_directories && copy_data_from_src_to_dest_directories
  fi
}

function update_core_variables_if_changed() {
  if [[ -n "$USER_DIB_APP_PROJECT" && "$DIB_APP_PROJECT" != "$USER_DIB_APP_PROJECT" ]]
  then
    export DIB_APP_PROJECT=$USER_DIB_APP_PROJECT
  fi

  if [[ -n "$USER_DIB_APP_FRAMEWORK" &&  "$DIB_APP_FRAMEWORK" != "$USER_DIB_APP_FRAMEWORK" ]]
  then
    export DIB_APP_FRAMEWORK=$USER_DIB_APP_FRAMEWORK
  fi

  if [[ -n "$USER_DIB_APP_IMAGE" && "$DIB_APP_IMAGE" != "$USER_DIB_APP_IMAGE" ]]
  then
    export DIB_APP_IMAGE=$USER_DIB_APP_IMAGE
  fi
}

function update_midsection_variables_if_changed() {
  if [[ -n "$USER_DIB_APP_BUILD_SRC" && "$DIB_APP_BUILD_SRC" != "$USER_DIB_APP_BUILD_SRC" ]]
  then
    export DIB_APP_BUILD_SRC=$USER_DIB_APP_BUILD_SRC
  fi

  if [[ -n "$USER_DIB_APP_BUILD_DEST" && "$DIB_APP_BUILD_DEST" != "$USER_DIB_APP_BUILD_DEST" ]]
  then
    export DIB_APP_BUILD_DEST=$USER_DIB_APP_BUILD_DEST
  fi

  if [[ -n "$USER_DIB_APP_ENVIRONMENT" && "$DIB_APP_ENVIRONMENT" != "$USER_DIB_APP_ENVIRONMENT" ]]
  then
    export DIB_APP_ENVIRONMENT=$USER_DIB_APP_ENVIRONMENT
  fi
}

function update_template_variables_if_changed() {
  if [[ -n "$USER_DIB_APP_IMAGE_TAG" && "$DIB_APP_IMAGE_TAG" != "$USER_DIB_APP_IMAGE_TAG" ]]
  then
    export DIB_APP_IMAGE_TAG=$USER_DIB_APP_IMAGE_TAG
  fi
}

function update_cache_data_if_changed() {
  case "$1"
  in
    core) update_core_variables_if_changed;;
    midsection) update_midsection_variables_if_changed;;
    template) update_template_variables_if_changed;;
  esac
}

function format_root_cache_file() {
  export DIB_APP_ROOT_CACHE_FILE="${DIB_APP_ROOT_CACHE_FILE/$ROOT_CACHE_DIR_TEMPLATE/$DIB_APP_KEY}"
  export DIB_APP_ROOT_CACHE_FILE_COPY="${DIB_APP_ROOT_CACHE_FILE_COPY/$ROOT_CACHE_DIR_TEMPLATE/$DIB_APP_KEY}"
}

function save_data_to_root_cache() {
  create_directory_if_not_exist "$(dirname "$DIB_APP_ROOT_CACHE_FILE")"
  
  cat 1> "$DIB_APP_ROOT_CACHE_FILE" <<EOF
DIB_APP_FRAMEWORK=${APP_FRAMEWORK:-}
DIB_APP_PROJECT=${APP_PROJECT:-}
DIB_APP_IMAGE=${APP_IMAGE:-}
DIB_APP_ENVIRONMENT=${APP_ENVIRONMENT:-}
DIB_APP_CONFIG_DIR=${DIB_APP_CONFIG_DIR:-}
DIB_APP_COMPOSE_DIR=${DIB_APP_COMPOSE_DIR:-}
DIB_APP_COMPOSE_K8S_DIR=${DIB_APP_COMPOSE_K8S_DIR:-}
DIB_APP_K8S_ANNOTATIONS_DIR=${DIB_APP_K8S_ANNOTATIONS_DIR:-}
DIB_APP_PROJECT_ENV_DIR=${DIB_APP_PROJECT_ENV_DIR:-}
DIB_APP_SERVICE_ENV_DIR=${DIB_APP_SERVICE_ENV_DIR:-}
DIB_APP_COMMON_ENV_DIR=${DIB_APP_COMMON_ENV_DIR:-}
DIB_APP_CACHE_DIR=${DIB_APP_CACHE_DIR:-}
DIB_APP_RUN_DIR=${DIB_APP_RUN_DIR:-}
DIB_APP_KEYSTORES_SRC=${DIB_APP_KEYSTORES_SRC:-}
DIB_APP_BUILD_SRC=${DIB_APP_BUILD_SRC:-}
DIB_APP_BUILD_DEST=${DIB_APP_BUILD_DEST:-}
DIB_CI_JOB=${CI_JOB:-}
DIB_APP_KEYSTORES_DEST=${DIB_APP_KEYSTORES_DEST:-}
EOF
}

function clear_root_cache() {
  cat 1> "$DIB_APP_ROOT_CACHE_FILE" <<EOF
DIB_APP_FRAMEWORK=
DIB_APP_PROJECT=
DIB_APP_IMAGE=
DIB_APP_ENVIRONMENT=
DIB_APP_CONFIG_DIR=
DIB_APP_COMPOSE_DIR=
DIB_APP_COMPOSE_K8S_DIR=
DIB_APP_K8S_ANNOTATIONS_DIR=
DIB_APP_PROJECT_ENV_DIR=
DIB_APP_SERVICE_ENV_DIR=
DIB_APP_COMMON_ENV_DIR=
DIB_APP_CACHE_DIR=
DIB_APP_RUN_DIR=
DIB_APP_KEYSTORES_SRC=
DIB_APP_BUILD_SRC=
DIB_APP_BUILD_DEST=
DIB_CI_JOB=
DIB_APP_KEYSTORES_DEST=
EOF
}

function save_data_to_app_cache() {
  create_directory_if_not_exist "$(dirname "$DIB_APP_CACHE_FILE")"

  cat 1> "$DIB_APP_CACHE_FILE" <<EOF
DIB_APP_IMAGE_TAG=${APP_IMAGE_TAG:-}
DIB_APP_KUBERNETES_NAMESPACE=${APP_KUBERNETES_NAMESPACE:-}
DIB_APP_DB_CONNECTION_POOL=${APP_DB_CONNECTION_POOL:-}
DIB_APP_KUBERNETES_CONTEXT=${APP_KUBERNETES_CONTEXT:-}
DIB_APP_NPM_RUN_COMMANDS=${APP_NPM_RUN_COMMANDS:-}
DIB_APP_BASE_HREF=${APP_BASE_HREF:-}
DIB_APP_DEPLOY_URL=${APP_DEPLOY_URL:-}
DIB_APP_BUILD_CONFIGURATION=${APP_BUILD_CONFIGURATION:-}
DIB_APP_NPM_BUILD_COMMAND_DELIMITER=${APP_NPM_BUILD_COMMAND_DELIMITER:-}
DIB_APP_REPO=${APP_REPO:-}
DIB_APP_PORT=${APP_PORT:-}
DIB_APPS_CONTAINER_REGISTRY=${APPS_CONTAINER_REGISTRY:-}
DIB_DOCKER_LOGIN_USERNAME=${DOCKER_LOGIN_USERNAME:-}
DIB_DOCKER_LOGIN_PASSWORD=${DOCKER_LOGIN_PASSWORD:-}
DIB_DOCKER_COMPOSE_NETWORK_MODE=${DOCKER_COMPOSE_NETWORK_MODE:-}
DIB_DOCKER_COMPOSE_DEPLOY_REPLICAS=${DOCKER_COMPOSE_DEPLOY_REPLICAS:-}
DIB_DOCKER_COMPOSE_HEALTHCHECK_START_PERIOD=${DOCKER_COMPOSE_HEALTHCHECK_START_PERIOD:-}
DIB_DOCKER_COMPOSE_HEALTHCHECK_INTERVAL=${DOCKER_COMPOSE_HEALTHCHECK_INTERVAL:-}
DIB_DOCKER_COMPOSE_HEALTHCHECK_TIMEOUT=${DOCKER_COMPOSE_HEALTHCHECK_TIMEOUT:-}
DIB_DOCKER_COMPOSE_HEALTHCHECK_RETRIES=${DOCKER_COMPOSE_HEALTHCHECK_RETRIES:-}
DIB_KOMPOSE_IMAGE_PULL_SECRET=${KOMPOSE_IMAGE_PULL_SECRET:-}
DIB_KOMPOSE_IMAGE_PULL_POLICY=${KOMPOSE_IMAGE_PULL_POLICY:-}
DIB_KOMPOSE_SERVICE_TYPE=${KOMPOSE_SERVICE_TYPE:-}
DIB_KOMPOSE_SERVICE_EXPOSE=${KOMPOSE_SERVICE_EXPOSE:-}
DIB_KOMPOSE_SERVICE_EXPOSE_TLS_SECRET=${KOMPOSE_SERVICE_EXPOSE_TLS_SECRET:-}
DIB_KOMPOSE_SERVICE_NODEPORT_PORT=${KOMPOSE_SERVICE_NODEPORT_PORT:-}
DIB_KUBECONFIGS=${KUBECONFIGS:-}
DIB_KUBERNETES_SERVICE_LABEL=${KUBERNETES_SERVICE_LABEL:-}
KUBE_HOME=${KUBE_HOME:-}
EOF
}

## -- finish
