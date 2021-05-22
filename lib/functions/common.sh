#!/bin/bash
#
# File: common.sh -> common script operations
#
# Usage: source common.sh
#
#

## - start here

function msg() {
  echo -e "$1"
}

function copy_config_files() {
  local config_dir="$1" app_build_dest="$2"

  msg 'Copying configuration files ...'

  ensure_paths_exist "$config_dir $app_build_dest"
  rsync -av --exclude="application*properties*" --exclude="*.copy" $config_dir/ $app_build_dest
}

function copy_docker_project() {
  local gitignore_patterns= hgignore_patterns=

  msg 'Copying docker project ...'

  if [[ -n "$DIB_APP_BUILD_SRC" ]]
  then
    ensure_paths_exist "$DIB_APP_BUILD_DEST"

    if [[ -f "$DIB_APP_BUILD_SRC/.gitignore" ]]
    then
      gitignore_patterns="--exclude-from=$DIB_APP_BUILD_SRC/.gitignore"
    fi

    if [[ -f "$DIB_APP_BUILD_SRC/.hgignore" ]]
    then
      hgignore_patterns="--exclude-from=$DIB_APP_BUILD_SRC/.hgignore"
    fi

    rm -rf $DIB_APP_BUILD_DEST/*
    rsync -av --exclude='.git/' $gitignore_patterns $hgignore_patterns $DIB_APP_BUILD_SRC/ $DIB_APP_BUILD_DEST
  fi
}

function abort_build_process() {
  msg 'docker image build process aborted'
  exit 1
}

function create_directory_if_not_exist() {
  local directory="$1"
  [[ -d "$directory" ]] || mkdir -p "$directory"
}

function ensure_paths_exist() {
  local paths="$1"

  for path in $paths
  do
    [[ -e "$path" ]] || { echo "$path must exist before."; exit 1; } 
  done
}

function create_directories_if_not_exist() {
  local directories="$1"

  for directory in $directories
  do
    [[ -d "$directory" ]] || mkdir -p $directory 
  done
}

function ensure_dir_paths_exist() {
  local dir_paths=

  dir_paths="$DIB_APP_BUILD_DEST $DIB_APP_CONFIG_DIR $DIB_APP_COMPOSE_DIR"
  dir_paths="$dir_paths $DIB_APP_K8S_ANNOTATIONS_DIR $DIB_APP_CACHE_DIR $DIB_APP_KEYSTORES_SRC"

  ensure_paths_exist "$dir_paths"
}

function is_kompose_version_valid() {
  local kompose_version=$($KOMPOSE_CMD version) minor_version=

  if grep -qE '^1' <<< "$kompose_version"
  then
    minor_version=$(grep -oE '\.\d{2}\.' <<< "$kompose_version"| tr -d '.')
    
    if [[ -n "$minor_version" && "$minor_version" -lt "21" ]]
    then
      return 1
    fi
  fi
  
  return 0
}

function get_app_image_tag() {
  local app_image_tag="${1:-latest}"

  if [[ "$USE_GIT_COMMIT" = "true" ]] && [[ -n "$GIT_COMMIT" ]]
  then
    app_image_tag=$(echo -ne $GIT_COMMIT | cut -c1-10)
  fi

  if [[ "$USE_MERCURIAL_REVISION" = "true" ]] && [[ -n "$MERCURIAL_REVISION" ]]
  then
    app_image_tag=$(echo -ne $MERCURIAL_REVISION | cut -c1-10)
  fi

  if [[ "$USE_BUILD_DATE" = "true" ]] && [[ -n "$BUILD_DATE" ]]
  then
    app_image_tag="${BUILD_DATE}-${app_image_tag}"
  fi

  if [[ "$USE_APP_ENVIRONMENT" = "true" ]]
  then
    case "$APP_ENVIRONMENT"
    in
      dev|develop|development) app_image_tag="dev-${app_image_tag/#dev-/}";;
      staging) app_image_tag="staging-${app_image_tag/#staging-/}";;
      test) app_image_tag="test-${app_image_tag/#test-/}";;
      beta) app_image_tag="beta-${app_image_tag/#beta-/}";;
      prod|production) app_image_tag="prod-${app_image_tag/#prod-/}";;
      demo) app_image_tag="demo-${app_image_tag/#demo-/}";;
      alpha) app_image_tag="alpha-${app_image_tag/#alpha-/}";;
      *) app_image_tag="${app_image_tag}";;
    esac
  fi

  printf '%s' $app_image_tag
}

function kubernetes_resources_annotations_changed() {
  local new_entries=$(diff \
    <(sort $DIB_APP_CHANGED_KUBERNETES_RESOURCES_ANNOTATIONS 2> /dev/null) \
    <(sort $DIB_APP_ORIGINAL_KUBERNETES_RESOURCES_ANNOTATIONS 2> /dev/null) | wc -l)
  
  [[ "$new_entries" -ne 0 ]] && return 0 || return 1
}

function update_env_file() {  
  local env_file="$1" changed_env_file="$2" symlinked_env_file="$3"
  
  if [[ -s "$changed_env_file" ]]
  then
    (
      cp "$changed_env_file" "$env_file"
      [[ -h "$symlinked_env_file" ]] || ln -s "$env_file" "$symlinked_env_file"
    ) 2> /dev/null
  else
    if [[ ! -f "$changed_env_file" ]]
    then
      touch "$changed_env_file" && cp "$changed_env_file" "$env_file" && ln -s "$env_file" "$symlinked_env_file"
    elif [[ ! -h "$symlinked_env_file" ]]
    then
      cp "$changed_env_file" "$env_file" && ln -s "$env_file" "$symlinked_env_file"
    fi
  fi
}

function file_changes_detected() {
  local original_file="$1" changed_file="$2"

  [[ -f "$original_file" ]] || touch "$original_file"
  [[ -f "$changed_file"  ]] || touch "$changed_file"

  if [[ "$(diff $original_file $changed_file 2> /dev/null | wc -l)" -eq 0 ]]
  then
    return 1
  else
    return 0
  fi
}
  
function docker_compose_file_changed() {
  if file_changes_detected "$DIB_APP_COMPOSE_DOCKER_COMPOSE_ORIGINAL_FILE" "$DIB_APP_COMPOSE_DOCKER_COMPOSE_CHANGED_FILE"
  then
    cp "$DIB_APP_COMPOSE_DOCKER_COMPOSE_CHANGED_FILE" "$DIB_APP_COMPOSE_DOCKER_COMPOSE_ORIGINAL_FILE"
    return 0
  fi

  return 1
}

function app_project_env_file_changed() {
  if file_changes_detected "$DIB_APP_PROJECT_ENV_ORIGINAL_FILE" "$DIB_APP_PROJECT_ENV_CHANGED_FILE"
  then
    cp "$DIB_APP_PROJECT_ENV_CHANGED_FILE" "$DIB_APP_PROJECT_ENV_ORIGINAL_FILE"
    return 0
  fi

  return 1
}

function app_common_env_file_changed() {
  if file_changes_detected "$DIB_APP_COMMON_ENV_ORIGINAL_FILE" "$DIB_APP_COMMON_ENV_CHANGED_FILE"
  then
    cp "$DIB_APP_COMMON_ENV_CHANGED_FILE" "$DIB_APP_COMMON_ENV_ORIGINAL_FILE"
    return 0
  fi

  return 1
}

function app_service_env_file_changed() {
  if file_changes_detected "$DIB_APP_SERVICE_ENV_ORIGINAL_FILE" "$DIB_APP_SERVICE_ENV_CHANGED_FILE"
  then
    cp "$DIB_APP_SERVICE_ENV_CHANGED_FILE" "$DIB_APP_SERVICE_ENV_ORIGINAL_FILE"
    return 0
  fi

  return 1
}

function app_env_file_changed() {
  if file_changes_detected "$DIB_APP_ENV_ORIGINAL_FILE" "$DIB_APP_ENV_CHANGED_FILE"
  then
    cp "$DIB_APP_ENV_CHANGED_FILE" "$DIB_APP_ENV_ORIGINAL_FILE"
    return 0
  fi

  return 1
}

function check_app_dependencies() {
  if [[ -x "$DOCKER_CMD" ]] 
  then
    msg 'docker already installed successfully'
  else
    msg '
    Oops, docker command not found.
    Please install and continue since this command helps you to build, run and push your Docker images
    '
  fi

  if [[ -x "$DOCKER_COMPOSE_CMD" ]] 
  then
    msg 'docker-compose installed successfully'
  else
    msg '
    Oops, docker-compose command not found.
    Please install and continue since this command helps you to build and run your Docker images collectively
  '
  fi

  if [[ -x "$KOMPOSE_CMD" ]]
  then
    msg 'kompose already installed successfully'
  else
    msg '
    Oops, kompose command not found.
    Please install and continue since this command helps you to convert your docker-compose files to Kubernetes manifests.
    '
  fi

  if [[ -x "$KUBECTL_CMD" ]] 
  then
    msg 'kubectl already installed successfully'
  else
    msg '
    Oops, kubectl command not found.
    Please install and continue since this command helps you to interact with the apiserver 
    inside your Kubernetes master node for various kubernetes operations 
    such as doing deployments, querying the state of your clusters and more.
    '
  fi

  if [[ -x "$NANO_CMD" ]] 
  then
    msg 'nano already installed successfully'
  else
    msg '
    Oops, nano command not found.
    Please install and continue since this command helps you to edit some files as your default editor.'
  fi
}

function check_kompose_validity() {
  if ! is_kompose_version_valid
  then
    msg "Invalid kompose command version. Please upgrade to a version greater than 1.20.x"
    exit 1
  fi
}

function check_app_environment_validity() {
  if [[ -z "$APP_ENVIRONMENT" ]] || ! echo -ne "$APP_ENVIRONMENT"| grep -qE "$DIB_APP_ENVIRONMENTS"
  then
    msg "App environment must be in $DIB_APP_ENVIRONMENTS"
    exit 1
  fi
}

function check_app_framework_validity() {
  if [[ -z "$APP_FRAMEWORK" ]] || ! echo -ne "$APP_FRAMEWORK"| grep -qE "$DIB_APP_FRAMEWORKS"
  then
    msg "App framework must be in $DIB_APP_FRAMEWORKS"
    exit 1
  fi
}

function check_path_validity() {
  local path="$1"

  if [[ -z "$path" ]] || echo -ne "$path" | grep -qE "$DIB_APP_INVALID_PATH_TOKENS"
  then
    msg "Invalid path. No path token should match '$DIB_APP_INVALID_PATH_TOKENS'"
    exit 1
  fi
}

function check_parameter_validity() {
  local parameter="$1" parameter_placeholder="$2"

  if [[ "$parameter" == "$parameter_placeholder" ]]
  then
    msg "Invalid parameter. Use a different value from placeholder value '$parameter_placeholder'"
    exit 1
  fi
}

function source_envvars_from_file() {
  local file="$1"

  sed -E -e '/^export/!s/^/export /g' -e '/^$/d' -e '/^[[:space:]]+$/d' "$file" 1> "$DIB_APP_TMP_FILE"
  
  source "$DIB_APP_TMP_FILE"
}

function get_all_envvars() {
  get_globals_envvars
  get_app_envvars
  get_docker_envvars
  get_kompose_envvars
  get_kubernetes_envvars
}

function get_globals_envvars() {
  cat <<EOF
DIB_HOME=$DIB_HOME
DIB_USE_GIT_COMMIT=$USE_GIT_COMMIT
DIB_USE_BUILD_DATE=$USE_BUILD_DATE
DIB_USE_APP_ENVIRONMENT=$USE_APP_ENVIRONMENT
DIB_CI_JOB=$CI_JOB
EOF
}

function get_app_envvars() {
  cat <<EOF
DIB_APP_PROJECT=$APP_PROJECT
DIB_APP_FRAMEWORK=$APP_FRAMEWORK
DIB_APP_ENVIRONMENT=$APP_ENVIRONMENT
DIB_APP_IMAGE_TAG=$APP_IMAGE_TAG
DIB_APP_DB_CONNECTION_POOL=$APP_DB_CONNECTION_POOL
DIB_APP_PACKAGER_RUN_COMMANDS=$APP_PACKAGER_RUN_COMMANDS
DIB_APP_BASE_HREF=$APP_BASE_HREF
DIB_APP_DEPLOY_URL=$APP_DEPLOY_URL
DIB_APP_BUILD_CONFIGURATION=$APP_BUILD_CONFIGURATION
DIB_APP_PACKAGER_BUILD_COMMAND_DELIMITER=$APP_PACKAGER_BUILD_COMMAND_DELIMITER
DIB_APP_REPO=$APP_REPO
DIB_APP_PORT=$APP_PORT
DIB_APP_BUILD_SRC=$DIB_APP_BUILD_SRC
DIB_APP_BUILD_DEST=$DIB_APP_BUILD_DEST
EOF
}

function get_docker_envvars() {
  cat <<EOF
DIB_DOCKER_LOGIN_USERNAME=$DOCKER_LOGIN_USERNAME
DIB_DOCKER_LOGIN_PASSWORD=$DOCKER_LOGIN_PASSWORD
DIB_APPS_CONTAINER_REGISTRY=$DIB_APPS_CONTAINER_REGISTRY
DIB_DOCKER_COMPOSE_NETWORK_MODE=$DOCKER_COMPOSE_NETWORK_MODE
DIB_DOCKER_COMPOSE_DEPLOY_REPLICAS=$DOCKER_COMPOSE_DEPLOY_REPLICAS
DIB_DOCKER_COMPOSE_HEALTHCHECK_START_PERIOD=$DOCKER_COMPOSE_HEALTHCHECK_START_PERIOD
DIB_DOCKER_COMPOSE_HEALTHCHECK_INTERVAL=$DOCKER_COMPOSE_HEALTHCHECK_INTERVAL
DIB_DOCKER_COMPOSE_HEALTHCHECK_TIMEOUT=$DOCKER_COMPOSE_HEALTHCHECK_TIMEOUT
DIB_DOCKER_COMPOSE_HEALTHCHECK_RETRIES=$DOCKER_COMPOSE_HEALTHCHECK_RETRIES
EOF
}

function get_kompose_envvars() {
  cat <<EOF
DIB_KOMPOSE_IMAGE_PULL_SECRET=$KOMPOSE_IMAGE_PULL_SECRET
DIB_KOMPOSE_IMAGE_PULL_POLICY=$KOMPOSE_IMAGE_PULL_POLICY
DIB_KOMPOSE_SERVICE_TYPE=$KOMPOSE_SERVICE_TYPE
DIB_KOMPOSE_SERVICE_EXPOSE=$KOMPOSE_SERVICE_EXPOSE
DIB_KOMPOSE_SERVICE_EXPOSE_TLS_SECRET=$KOMPOSE_SERVICE_EXPOSE_TLS_SECRET
DIB_KOMPOSE_SERVICE_NODEPORT_PORT=$KOMPOSE_SERVICE_NODEPORT_PORT
EOF
}

function get_kubernetes_envvars() {
  cat <<EOF
KUBE_HOME=$KUBE_HOME
DIB_KUBECONFIGS=$KUBECONFIGS
DIB_KUBERNETES_SERVICE_LABEL=$KUBERNETES_SERVICE_LABEL
DIB_APP_KUBERNETES_NAMESPACE=$APP_KUBERNETES_NAMESPACE
DIB_APP_KUBERNETES_CONTEXT=$APP_KUBERNETES_CONTEXT
EOF
}

function should_show_help() {
  local help="${1:-nothing}"
  
  case "$help"
  in
    help|--help|-h) return 0;;
    *) return 1;;
  esac
}

function ensure_core_variables_validity() {
  check_parameter_validity "$APP_FRAMEWORK" "$DIB_APP_FRAMEWORK_PLACEHOLDER"
  check_parameter_validity "$APP_PROJECT" "$DIB_APP_PROJECT_PLACEHOLDER"
  check_parameter_validity "$APP_IMAGE" "$DIB_APP_IMAGE_PLACEHOLDER"
  check_parameter_validity "$APP_ENVIRONMENT" "$DIB_APP_ENVIRONMENT_PLACEHOLDER"
}

function columnize_items() {
  echo -ne "$1" | sed -E -e 's/[[:space:]]+//g' -e 's/,/\n/g' | grep -vE '^$' | grep -vE '^\s+$'
}

function check_app_key_validity() {
  if [[ -n "$DIB_APP_KEY" ]]
  then
    if ! echo -ne "$(get_project_value_by_app_key "$DIB_APP_KEY")" | grep -qE "$USER_DIB_APP_IMAGE$"
    then
      msg "Invalid app key '$DIB_APP_KEY'. Please try again."
      exit 1
    fi
  fi
}

function load_app_cache_file() {
  [[ -f "$DIB_APP_CACHE_FILE" ]] && source_envvars_from_file "$DIB_APP_CACHE_FILE" || :
}

function load_root_cache_file() {
  [[ -z "$DIB_APP_KEY" ]] && { msg "Please provide DIB_APP_KEY and try again."; exit 1; }
  format_root_cache_file
  [[ -f "$DIB_APP_ROOT_CACHE_FILE" ]] && source_envvars_from_file "$DIB_APP_ROOT_CACHE_FILE" || :
}

function perform_root_cache_operations() {
  load_root_cache_file
  update_cache_data_if_changed "core"
  load_core_data
  update_cache_data_if_changed "midsection"
}

function perform_app_cache_operations() {
  ensure_core_variables_validity
  load_paths_data
  load_app_cache_file
  update_cache_data_if_changed "template"
  load_template_data
  load_more_functions
}

function remove_tmp_file() {
  [[ -f "$DIB_APP_TMP_FILE" ]] && rm -f "$DIB_APP_TMP_FILE"
}

## -- finish
