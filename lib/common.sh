#!/bin/bash
#
# File: common.sh -> common script operations
#
# (c) 2021 Frederick Ofosu-Darko <fofosudarko@gmail.com>
#
# Usage: source common.sh
#
#

## - start here

function msg() {
  echo >&2 "$1"
}

function run_as() {
  if [[ "$USE_SUDO" = "true" ]]
  then
    sudo su "$1" -c "$2"
  else
    $SHELL_CMD -c "$2"
  fi
}

function extract_exclude_patterns() {
  local path="$1" input_type="${2:-file}"

  case "$input_type"
  in
    file)
      grep -vE '^(\#|\!)' "$path" | grep -v '^$' | sed -e 's/^/--exclude="/' -e 's/$/"/g'| tr '\n' ' '
    ;;
    string)
      echo -ne "$path" | grep -vE '^(\#|\!)' | grep -v '^$' | sed -e 's/^/--exclude="/' -e 's/$/"/g'| tr '\n' ' '
    ;;
  esac
}

function copy_docker_project() {
  local ci_project="$1" docker_project="$2" gitignore_patterns= hgignore_patterns=

  msg 'Copying docker project ...'

  ensure_paths_exist "$docker_project"

  if [[ -f "$ci_project/.gitignore" ]]
  then
    gitignore_patterns="$(extract_exclude_patterns "$ci_project/.gitignore")"
  fi

  if [[ -f "$ci_project/.hgignore" ]]
  then
    hgignore_patterns="$(extract_exclude_patterns "$ci_project/.hgignore")"
  fi
  
  rm -rf $docker_project/*
  rsync -av --exclude='.git/' $gitignore_patterns $hgignore_patterns $ci_project/ $docker_project
}

function copy_docker_build_files() { 
  local build_files="$1" docker_project="$2"
  local docker_compose_template="$DIB_APP_COMPOSE_COMPOSE_TEMPLATE_FILE"
  local docker_compose_out="$DIB_APP_CONFIG_DIR/docker-compose.yml"
  
  msg 'Copying docker build files ...'

  ensure_paths_exist "$build_files $docker_project"

  format_docker_compose_template "$docker_compose_template" "$docker_compose_out"
  
  rsync -av --exclude='$(basename $docker_compose_template)' $build_files $docker_project
}

function copy_config_files() {
  local config_dir="$1" app_build_dest="$2" 
  local exclude_patterns="$(extract_exclude_patterns "$DIB_APP_CONFIG_EXCLUDE_PATTERNS" 'string')"

  msg 'Copying configuration files ...'

  ensure_paths_exist "$config_dir $app_build_dest"
  
  rsync -av $exclude_patterns $config_dir/ $app_build_dest
}

function format_docker_compose_template() {
  local docker_compose_template="$1" docker_compose_out="$2"
  
  if [[ -s "$docker_compose_template" ]]
  then
    sed -e "s/@@DIB_APP_IMAGE@@/${APP_IMAGE}/g" \
    -e "s/@@DIB_APP_PROJECT@@/${APP_PROJECT}/g" \
    -e "s/@@DIB_CONTAINER_REGISTRY@@/${DIB_APPS_CONTAINER_REGISTRY}/g" \
    -e "s/@@DIB_APP_IMAGE_TAG@@/${APP_IMAGE_TAG}/g" \
    -e "s/@@DIB_APP_ENVIRONMENT@@/${APP_ENVIRONMENT}/g" \
    -e "s/@@DIB_APP_FRAMEWORK@@/${APP_FRAMEWORK}/g" \
    -e "s/@@DIB_APP_NPM_RUN_COMMANDS@@/${APP_NPM_RUN_COMMANDS}/g" \
    -e "s/@@DIB_KOMPOSE_IMAGE_PULL_SECRET@@/${KOMPOSE_IMAGE_PULL_SECRET}/g" \
    -e "s/@@DIB_KOMPOSE_IMAGE_PULL_POLICY@@/${KOMPOSE_IMAGE_PULL_POLICY}/g" \
    -e "s/@@DIB_KOMPOSE_SERVICE_TYPE@@/${KOMPOSE_SERVICE_TYPE}/g" \
    -e "s/@@DIB_KOMPOSE_SERVICE_EXPOSE@@/${KOMPOSE_SERVICE_EXPOSE}/g" \
    -e "s/@@DIB_KOMPOSE_SERVICE_EXPOSE_TLS_SECRET@@/${KOMPOSE_SERVICE_EXPOSE_TLS_SECRET}/g" \
    -e "s/@@DIB_KOMPOSE_SERVICE_NODEPORT_PORT@@/${KOMPOSE_SERVICE_NODEPORT_PORT}/g" \
    -e "s/@@DIB_APP_BASE_HREF@@/${APP_BASE_HREF/\//\\/}/g" \
    -e "s/@@DIB_APP_DEPLOY_URL@@/${APP_DEPLOY_URL/\//\\/}/g" \
    -e "s/@@DIB_APP_BUILD_CONFIGURATION@@/${APP_BUILD_CONFIGURATION}/g" \
    -e "s/@@DIB_APP_REPO@@/${APP_REPO}/g" \
    -e "s/@@DIB_APP_NPM_BUILD_COMMAND_DELIMITER@@/${APP_NPM_BUILD_COMMAND_DELIMITER}/g" \
    -e "s/@@DIB_DOCKER_COMPOSE_NETWORK_MODE@@/${DOCKER_COMPOSE_NETWORK_MODE}/g" \
    -e "s/@@DIB_DOCKER_COMPOSE_DEPLOY_REPLICAS@@/${DOCKER_COMPOSE_DEPLOY_REPLICAS}/g" \
    -e "s/@@DIB_APP_PORT@@/${APP_PORT}/g" "$docker_compose_template" 1> "$docker_compose_out"
  else
    [[ ! -f "$docker_compose_out" ]] && touch "$docker_compose_out"
  fi
}

function update_env_file() {  
  local env_file="$1" changed_env_file="$2" original_env_file="$3" symlinked_env_file="$4"
  
  if [[ -s "$changed_env_file" ]]
  then
    cp $changed_env_file $original_env_file 2> /dev/null
    cp $changed_env_file $env_file 2> /dev/null
    [[ -h "$symlinked_env_file" ]] || ln -s $env_file $symlinked_env_file 2> /dev/null
  else
    test -f $changed_env_file || \
      touch $changed_env_file && cp $changed_env_file $env_file && ln -s $env_file $symlinked_env_file
  fi
}

function detect_file_changed() {
  local original_file="$1" changed_file="$2"

  if [[ ! -f "$original_file" || ! -f "$changed_file" ]]
  then
    return 0
  fi

  if [[ "$(diff $original_file $changed_file 2> /dev/null| wc -l)" -eq 0 ]]
  then
    return 1
  fi

  return 0
}

function abort_build_process() {
  msg 'docker image build process aborted'
  exit 1
}

function create_directory_if_not_exist() {
  local directory="$1"

  [[ -d "$directory" ]] || mkdir -p "$directory"
}

function create_default_directories_on_init() {
  local default_directories=(
    ${DIB_CACHE}
    ${DIB_APPS_DIR}
    ${DIB_APPS_CONFIG_DIR}
    ${DIB_APPS_KEYSTORES_DIR}
    ${DIB_APPS_COMPOSE_DIR}
    ${DIB_APPS_ENV_DIR}
    ${DIB_APPS_K8S_ANNOTATIONS_DIR}
    ${DIB_APPS_KUBERNETES_DIR}
    ${DIB_APPS_CACHE_DIR}
    ${DIB_APP_CACHE_DIR}
  )

  for default_directory in ${default_directories[@]}
  do
    [[ -d "$default_directory" ]] || mkdir -p "$default_directory"
  done
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

function set_app_frontend_build_mode() {
  case "$APP_BUILD_MODE"
  in
    spa)
      cp $DIB_APP_BUILD_DEST/Dockerfile-spa $DOCKER_FILE
    ;;
    universal)
      cp $DIB_APP_BUILD_DEST/Dockerfile-universal $DOCKER_FILE
    ;;
    *)
      msg "app build mode '$APP_BUILD_MODE' unknown"
      return 1
    ;;
  esac

  return 0
}

function get_app_image_tag() {
  local app_image_tag="${1:-'latest'}"

  if [[ "$USE_GIT_COMMIT" = "true" ]] && [[ -n "$GIT_COMMIT" ]]
  then
    app_image_tag=$(echo -ne $GIT_COMMIT| cut -c1-10)
  fi

  if [[ "$USE_BUILD_DATE" = "true" ]] && [[ -n "$BUILD_DATE" ]]
  then
    app_image_tag="${BUILD_DATE}-${app_image_tag}"
  fi

  case "$APP_ENVIRONMENT"
  in
    dev|develop|development) app_image_tag="dev-${app_image_tag}";;
    staging) app_image_tag="staging-${app_image_tag}";;
    beta) app_image_tag="beta-${app_image_tag}";;
    prod|production) app_image_tag="prod-${app_image_tag}";;
    demo) app_image_tag="demo-${app_image_tag}";;
    alpha) app_image_tag="alpha-${app_image_tag}";;
    *) app_image_tag="${app_image_tag}";;
  esac

  printf '%s' $app_image_tag
}

function kubernetes_resources_annotations_changed() {
  local changed_kubernetes_resources_annotations=$DIB_APP_K8S_ANNOTATIONS_DIR/*changed
  local original_kubernetes_resources_annotations=$DIB_APP_K8S_ANNOTATIONS_DIR/*original
  local new_entries=$(diff \
    <(sort $changed_kubernetes_resources_annotations 2> /dev/null) \
    <(sort $original_kubernetes_resources_annotations 2> /dev/null) | wc -l)
  
  if [[ "$new_entries" -ne 0 ]]
  then
    return 0
  fi
  
  return 1
}

function env_file_changed() {
  local env_file="$1" original_env_file="$2" changed_env_file="$3" symlinked_env_file="$4"

  ensure_paths_exist "$changed_env_file"
  
  if detect_file_changed "$original_env_file" "$changed_env_file" || [[ ! -e "$symlinked_env_file" ]]
  then
    update_env_file "$env_file" "$changed_env_file" "$original_env_file" "$symlinked_env_file"
    return 0
  fi

  return 1
}

function app_project_env_file_changed() {
  local env_file=$DIB_APP_PROJECT_ENV_DIR/project.env
  local original_env_file=$DIB_APP_PROJECT_ENV_DIR/project.env.original
  local symlinked_env_file=$DIB_APP_COMPOSE_DIR/${APP_PROJECT}-${APP_FRAMEWORK}-project.env
  local changed_env_file="$DIB_APP_PROJECT_ENV_CHANGED_FILE"
  
  return $(env_file_changed "$env_file" "$original_env_file" "$changed_env_file" "$symlinked_env_file")
}

function app_common_env_file_changed() {
  local env_file=$DIB_APP_COMMON_ENV_DIR/common.env
  local original_env_file=$DIB_APP_COMMON_ENV_DIR/common.env.original
  local symlinked_env_file=$DIB_APP_COMPOSE_DIR/${APP_PROJECT}-${APP_FRAMEWORK}-${APP_ENVIRONMENT}-common.env
  local changed_env_file="$DIB_APP_COMMON_ENV_CHANGED_FILE"
  
  return $(env_file_changed "$env_file" "$original_env_file" "$changed_env_file" "$symlinked_env_file")
}

function app_service_env_file_changed() {
  local env_file=$DIB_APP_SERVICE_ENV_DIR/service.env
  local original_env_file=$DIB_APP_SERVICE_ENV_DIR/service.env.original
  local symlinked_env_file=$DIB_APP_COMPOSE_DIR/${APP_IMAGE}-service.env
  local changed_env_file="$DIB_APP_SERVICE_ENV_CHANGED_FILE"
  
  return $(env_file_changed "$env_file" "$original_env_file" "$changed_env_file" "$symlinked_env_file")
}

function app_env_file_changed() {
  local env_file=$DIB_APP_COMPOSE_DIR/app.env
  local original_env_file=$DIB_APP_COMPOSE_DIR/app.env.original
  local symlinked_env_file=$DIB_APP_COMPOSE_DIR/${APP_IMAGE}-app.env
  local changed_env_file="$DIB_APP_ENV_CHANGED_FILE"
  
  return $(env_file_changed "$env_file" "$original_env_file" "$changed_env_file" "$symlinked_env_file")
}

function check_app_dependencies() {
  if [[ -x "$DOCKER_CMD" ]] 
  then
    msg 'docker already installed successfully'
  else
    msg '
    Oops, docker command not found.
    Please install and continue since this command helps you to build and push your Docker images
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

  exit 0
}

function check_kompose_validity() {
  if ! is_kompose_version_valid
  then
    msg "Invalid kompose command version. Please upgrade to a version greater than 1.20.x"
    exit 1
  fi
}

function check_run_command_validity() {
  if [[ -z "$DIB_RUN_COMMAND" ]] || ! echo -ne "$DIB_RUN_COMMAND"| grep -qE "$DIB_RUN_COMMANDS"
  then
    msg "Run command must be in $DIB_RUN_COMMANDS"
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

  if [[ -z "$path" ]] || echo -ne "$path"| grep -qE "$DIB_APP_INVALID_PATH_TOKENS"
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

function show_help() {
  msg "This is a help message"
  exit 0
}

function source_envvars_from_file() {
  local file="$1" tmp_file=$(mktemp)

  sed '/^export/!s/^/export /g' "$file" 1> "$tmp_file"

  source "$tmp_file" && rm -f "$tmp_file"
}

function execute_env_command() {
  local env_type="$1"

  case "$env_type"
  in
    all) 
      get_all_envvars
    ;;
    globals) 
      get_globals_envvars
    ;;
    users) 
      get_users_envvars
    ;;
    app) 
      get_app_envvars
    ;;
    docker) 
      get_docker_envvars
    ;;
    kompose) 
      get_kompose_envvars
    ;;
    kubernetes) 
      get_kubernetes_envvars
    ;;
    *)
      get_all_envvars
    ;;
  esac
}

function get_all_envvars() {
  get_globals_envvars
  get_users_envvars
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
DIB_USE_SUDO=$USE_SUDO
DIB_CI_WORKSPACE=$CI_WORKSPACE
DIB_CI_JOB=$CI_JOB
EOF
}

function get_users_envvars() {
  cat <<EOF
DIB_USER=$DIB_USER
DIB_CI_USER=$CI_USER
DIB_SUPER_USER=$SUPER_USER
EOF
}

function get_app_envvars() {
  cat <<EOF
DIB_APP_PROJECT=$APP_PROJECT
DIB_APP_FRAMEWORK=$APP_FRAMEWORK
DIB_APP_ENVIRONMENT=$APP_ENVIRONMENT
DIB_APP_IMAGE_TAG=$APP_IMAGE_TAG
DIB_APP_DB_CONNECTION_POOL=$APP_DB_CONNECTION_POOL
DIB_APP_BUILD_MODE=$APP_BUILD_MODE
DIB_APP_NPM_RUN_COMMANDS=$APP_NPM_RUN_COMMANDS
DIB_APP_BASE_HREF=$APP_BASE_HREF
DIB_APP_DEPLOY_URL=$APP_DEPLOY_URL
DIB_APP_BUILD_CONFIGURATION=$APP_BUILD_CONFIGURATION
DIB_APP_NPM_BUILD_COMMAND_DELIMITER=$APP_NPM_BUILD_COMMAND_DELIMITER
DIB_APP_REPO=$APP_REPO
DIB_APP_PORT=$APP_PORT
DIB_APP_BUILD_SRC=$DIB_APP_BUILD_SRC
EOF
}

function get_docker_envvars() {
  cat <<EOF
DIB_DOCKER_LOGIN_USERNAME=$DOCKER_LOGIN_USERNAME
DIB_DOCKER_LOGIN_PASSWORD=$DOCKER_LOGIN_PASSWORD
DIB_CONTAINER_REGISTRY=$DIB_APPS_CONTAINER_REGISTRY
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

function execute_init_command() {
  
  function create_directories_on_init() {
    local directories=

    directories="$DIB_CACHE $DIB_APPS_DIR $DIB_APPS_CONFIG_DIR $DIB_APPS_KEYSTORES_DIR"
    directories="$directories $DIB_APPS_COMPOSE_DIR $DIB_APPS_ENV_DIR $DIB_APPS_K8S_ANNOTATIONS_DIR"
    directories="$directories $DIB_APPS_KUBERNETES_DIR $DIB_APPS_CACHE_DIR"

    create_directories_if_not_exist "$directories"
  }

  check_parameter_validity "$DIB_HOME" "$DIB_HOME_PLACEHOLDER"
  create_directories_on_init
  exit 0
}

function execute_goto_command() {
  
  function save_data_to_root_cache_on_goto() {
  if [[ -f "$DIB_APP_ROOT_CACHE_FILE" ]]
  then
    cp "$DIB_APP_ROOT_CACHE_FILE" "$DIB_APP_ROOT_CACHE_FILE_COPY"
  fi

  cat 1> "$DIB_APP_ROOT_CACHE_FILE" <<EOF
DIB_APP_FRAMEWORK=$DIB_APP_FRAMEWORK
DIB_APP_PROJECT=$DIB_APP_PROJECT
DIB_APP_IMAGE=$DIB_APP_IMAGE
EOF
  }

  load_core
  check_parameter_validity "$DIB_HOME" "$DIB_HOME_PLACEHOLDER"
  check_parameter_validity "$APP_FRAMEWORK" "$DIB_APP_FRAMEWORK_PLACEHOLDER"
  check_parameter_validity "$APP_PROJECT" "$DIB_APP_PROJECT_PLACEHOLDER"
  check_parameter_validity "$APP_IMAGE" "$DIB_APP_IMAGE_PLACEHOLDER"
  check_app_framework_validity
  save_data_to_root_cache_on_goto
  exit 0
}

function execute_switch_command() {
  
  function create_directories_on_switch() {
    local directories=

    DIB_APP_CONFIG_DIR="$DIB_APPS_CONFIG_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$APP_ENVIRONMENT"
    DIB_APP_COMPOSE_DIR="$DIB_APPS_COMPOSE_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$APP_ENVIRONMENT"
    DIB_APP_COMPOSE_K8S_DIR="$DIB_APPS_COMPOSE_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$APP_ENVIRONMENT/kubernetes"
    DIB_APP_K8S_ANNOTATIONS_DIR="$DIB_APPS_K8S_ANNOTATIONS_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$APP_ENVIRONMENT"
    DIB_APP_PROJECT_ENV_DIR="$DIB_APPS_ENV_DIR/$APP_FRAMEWORK/$APP_PROJECT"
    DIB_APP_SERVICE_ENV_DIR="$DIB_APPS_ENV_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE"
    DIB_APP_COMMON_ENV_DIR="$DIB_APPS_ENV_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_ENVIRONMENT"
    DIB_APP_CACHE_DIR="$DIB_APPS_CACHE_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$APP_ENVIRONMENT"
    DIB_APP_KEYSTORES_SRC="$DIB_APPS_KEYSTORES_DIR/$APP_PROJECT/$APP_ENVIRONMENT/keystores"
    DIB_APP_BUILD_DEST="$DIB_APPS_DIR/$APP_FRAMEWORK/$APP_IMAGE/$APP_ENVIRONMENT/$CI_JOB"
    DIB_APP_KEYSTORES_DEST="$DIB_APP_BUILD_DEST"

    directories="$DIB_APP_CONFIG_DIR $DIB_APP_COMPOSE_DIR $DIB_APP_COMPOSE_K8S_DIR"
    directories="$directories $DIB_APP_K8S_ANNOTATIONS_DIR $DIB_APP_PROJECT_ENV_DIR"
    directories="$directories $DIB_APP_SERVICE_ENV_DIR $DIB_APP_COMMON_ENV_DIR $DIB_APP_CACHE_DIR"
    directories="$directories $DIB_APP_BUILD_DEST $DIB_APP_KEYSTORES_SRC"
  
    create_directories_if_not_exist "$directories"
  }

  function save_data_to_root_cache_on_switch() {
    if [[ -f "$DIB_APP_ROOT_CACHE_FILE" ]]
    then
      cp "$DIB_APP_ROOT_CACHE_FILE" "$DIB_APP_ROOT_CACHE_FILE_COPY"
    fi

    cat 1> "$DIB_APP_ROOT_CACHE_FILE" <<EOF
DIB_APP_FRAMEWORK=$APP_FRAMEWORK
DIB_APP_PROJECT=$APP_PROJECT
DIB_APP_IMAGE=$APP_IMAGE
DIB_APP_ENVIRONMENT=$APP_ENVIRONMENT
DIB_APP_CONFIG_DIR=$DIB_APP_CONFIG_DIR
DIB_APP_COMPOSE_DIR=$DIB_APP_COMPOSE_DIR
DIB_APP_COMPOSE_K8S_DIR=$DIB_APP_COMPOSE_K8S_DIR
DIB_APP_K8S_ANNOTATIONS_DIR=$DIB_APP_K8S_ANNOTATIONS_DIR
DIB_APP_PROJECT_ENV_DIR=$DIB_APP_PROJECT_ENV_DIR
DIB_APP_SERVICE_ENV_DIR=$DIB_APP_SERVICE_ENV_DIR
DIB_APP_COMMON_ENV_DIR=$DIB_APP_COMMON_ENV_DIR
DIB_APP_CACHE_DIR=$DIB_APP_CACHE_DIR
DIB_APP_KEYSTORES_SRC=$DIB_APP_KEYSTORES_SRC
DIB_CI_JOB=$CI_JOB
DIB_APP_BUILD_DEST=$DIB_APP_BUILD_DEST
DIB_APP_KEYSTORES_DEST=$DIB_APP_KEYSTORES_DEST
EOF
  }

  load_core
  check_parameter_validity "$APP_FRAMEWORK" "$DIB_APP_FRAMEWORK_PLACEHOLDER"
  check_parameter_validity "$APP_PROJECT" "$DIB_APP_PROJECT_PLACEHOLDER"
  check_parameter_validity "$APP_IMAGE" "$DIB_APP_IMAGE_PLACEHOLDER"
  check_parameter_validity "$APP_ENVIRONMENT" "$DIB_APP_ENVIRONMENT_PLACEHOLDER"
  check_app_framework_validity
  check_app_environment_validity
  create_directories_on_switch
  save_data_to_root_cache_on_switch
  exit 0
}

function execute_cache_command() {
  [[ -f "$DIB_APP_ROOT_CACHE_FILE" ]] && cat "$DIB_APP_ROOT_CACHE_FILE"
  exit 0
}

function execute_copy_command() {
  
  function create_directories_on_copy() {
    local directories=

    DIB_APP_CONFIG_DIR="$DIB_APPS_CONFIG_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$APP_ENVIRONMENT"
    DIB_APP_COMPOSE_DIR="$DIB_APPS_COMPOSE_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$APP_ENVIRONMENT"
    DIB_APP_COMPOSE_K8S_DIR="$DIB_APPS_COMPOSE_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$APP_ENVIRONMENT/kubernetes"
    DIB_APP_K8S_ANNOTATIONS_DIR="$DIB_APPS_K8S_ANNOTATIONS_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$APP_ENVIRONMENT"
    DIB_APP_PROJECT_ENV_DIR="$DIB_APPS_ENV_DIR/$APP_FRAMEWORK/$APP_PROJECT"
    DIB_APP_SERVICE_ENV_DIR="$DIB_APPS_ENV_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE"
    DIB_APP_COMMON_ENV_DIR="$DIB_APPS_ENV_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_ENVIRONMENT"
    DIB_APP_CACHE_DIR="$DIB_APPS_CACHE_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE/$APP_ENVIRONMENT"
    DIB_APP_KEYSTORES_SRC="$DIB_APPS_KEYSTORES_DIR/$APP_PROJECT/$APP_ENVIRONMENT/keystores"
    DIB_APP_BUILD_DEST="$DIB_APPS_DIR/$APP_FRAMEWORK/$APP_IMAGE/$APP_ENVIRONMENT/$CI_JOB"
    DIB_APP_KEYSTORES_DEST="$DIB_APP_BUILD_DEST"

    directories="$DIB_APP_CONFIG_DIR $DIB_APP_COMPOSE_DIR $DIB_APP_COMPOSE_K8S_DIR $DIB_APP_K8S_ANNOTATIONS_DIR"
    directories="$directories $DIB_APP_PROJECT_ENV_DIR $DIB_APP_SERVICE_ENV_DIR $DIB_APP_COMMON_ENV_DIR"
    directories="$directories $DIB_APP_CACHE_DIR $DIB_APP_KEYSTORES_SRC $DIB_APP_BUILD_DEST"

    create_directories_if_not_exist "$directories"
  }

  function save_data_to_root_cache_on_copy() {
    if [[ -f "$DIB_APP_ROOT_CACHE_FILE" ]]
    then
      cp "$DIB_APP_ROOT_CACHE_FILE" "$DIB_APP_ROOT_CACHE_FILE_COPY"
    fi

    cat 1> "$DIB_APP_ROOT_CACHE_FILE" <<EOF
DIB_APP_FRAMEWORK=$APP_FRAMEWORK
DIB_APP_PROJECT=$APP_PROJECT
DIB_APP_IMAGE=$APP_IMAGE
DIB_APP_ENVIRONMENT=$APP_ENVIRONMENT
DIB_APP_CONFIG_DIR=$DIB_APP_CONFIG_DIR
DIB_APP_COMPOSE_DIR=$DIB_APP_COMPOSE_DIR
DIB_APP_COMPOSE_K8S_DIR=$DIB_APP_COMPOSE_K8S_DIR
DIB_APP_K8S_ANNOTATIONS_DIR=$DIB_APP_K8S_ANNOTATIONS_DIR
DIB_APP_PROJECT_ENV_DIR=$DIB_APP_PROJECT_ENV_DIR
DIB_APP_SERVICE_ENV_DIR=$DIB_APP_SERVICE_ENV_DIR
DIB_APP_COMMON_ENV_DIR=$DIB_APP_COMMON_ENV_DIR
DIB_APP_CACHE_DIR=$DIB_APP_CACHE_DIR
DIB_APP_KEYSTORES_SRC=$DIB_APP_KEYSTORES_SRC
DIB_APP_BUILD_SRC=$DIB_APP_BUILD_SRC
DIB_APP_BUILD_DEST=$DIB_APP_BUILD_DEST
DIB_CI_JOB=$CI_JOB
DIB_APP_KEYSTORES_DEST=$DIB_APP_KEYSTORES_DEST
EOF
  }

  load_core
  create_directories_on_copy
  copy_docker_project "$DIB_APP_BUILD_SRC" "$DIB_APP_BUILD_DEST"
  save_data_to_root_cache_on_copy
  exit 0
}

function execute_reset_command() {
  
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
DIB_APP_KEYSTORES_SRC=
DIB_APP_BUILD_SRC=
DIB_APP_BUILD_DEST=
DIB_CI_JOB=
DIB_APP_KEYSTORES_DEST=
EOF
  }
  
  clear_root_cache
  exit 0
}

function substitute_core_variables_if_changed() {

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

function substitute_other_variables_if_changed() {

  if [[ -n "$USER_DIB_APP_BUILD_SRC" && "$DIB_APP_BUILD_SRC" != "$USER_DIB_APP_BUILD_SRC" ]]
  then
    export DIB_APP_BUILD_SRC=$USER_DIB_APP_BUILD_SRC
  fi

  if [[ -n "$USER_DIB_APP_BUILD_DEST" && "$DIB_APP_BUILD_DEST" != "$USER_DIB_APP_BUILD_DEST" ]]
  then
    export DIB_APP_BUILD_DEST=$USER_DIB_APP_BUILD_DEST
  fi

  if [[ -n "$USER_DIB_APP_IMAGE_TAG" && "$DIB_APP_IMAGE_TAG" != "$USER_DIB_APP_IMAGE_TAG" ]]
  then
    export DIB_APP_IMAGE_TAG=$USER_DIB_APP_IMAGE_TAG
  fi

  if [[ -n "$USER_DIB_APP_ENVIRONMENT" && "$DIB_APP_ENVIRONMENT" != "$USER_DIB_APP_ENVIRONMENT" ]]
  then
    export DIB_APP_ENVIRONMENT=$USER_DIB_APP_ENVIRONMENT
  fi
}

## -- finish
