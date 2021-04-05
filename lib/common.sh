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
  echo >&2 "$COMMAND: $1"
}

function run_as() {
  if [[ "$USE_SUDO" = "true" ]]
  then
    sudo su "$1" -c "$2"
  else
    su "$1" -c "$2"
  fi
}

function copy_docker_project() {
  local ci_project="$1" docker_project="$2"

  msg 'Copying docker project ...'
  
  run_as "$DOCKER_USER" "
  rm -rf $docker_project/*
  rsync -av --exclude='.git/' $ci_project $docker_project
"
}

function copy_docker_build_files() { 
  local build_files="$1" docker_project="$2"
  local docker_compose_template="$DOCKER_APP_CONFIG_DIR/docker-compose.template.yml"
  local docker_compose_file="$DOCKER_APP_CONFIG_DIR/docker-compose.yml"

  if [ -s "$docker_compose_template" ]
  then
    format_docker_compose_template "$docker_compose_template" "$docker_compose_file"
  fi

  msg 'Copying docker build files ...'
  
  run_as "$DOCKER_USER" "
  rsync -av --exclude='$(basename $docker_compose_template)' $build_files $docker_project 2> /dev/null
"
}

function format_docker_compose_template() {
  local docker_compose_template="$1" docker_compose_out="$2"
  
  if [[ -s "$docker_compose_template" ]]
  then
    run_as "$DOCKER_USER" "
      sed -e 's/@@DIB_APP_IMAGE@@/${APP_IMAGE}/g' \
      -e 's/@@DIB_APP_PROJECT@@/${APP_PROJECT}/g' \
      -e 's/@@DIB_CONTAINER_REGISTRY@@/${CONTAINER_REGISTRY}/g' \
      -e 's/@@DIB_APP_IMAGE_TAG@@/${APP_IMAGE_TAG}/g' \
      -e 's/@@DIB_APP_ENVIRONMENT@@/${APP_ENVIRONMENT}/g' \
      -e 's/@@DIB_APP_FRAMEWORK@@/${APP_FRAMEWORK}/g' \
      -e 's/@@DIB_APP_NPM_RUN_COMMANDS@@/${APP_NPM_RUN_COMMANDS}/g' \
      -e 's/@@DIB_KOMPOSE_IMAGE_PULL_SECRET@@/${KOMPOSE_IMAGE_PULL_SECRET}/g' \
      -e 's/@@DIB_KOMPOSE_IMAGE_PULL_POLICY@@/${KOMPOSE_IMAGE_PULL_POLICY}/g' \
      -e 's/@@DIB_KOMPOSE_SERVICE_TYPE@@/${KOMPOSE_SERVICE_TYPE}/g' \
      -e 's/@@DIB_KOMPOSE_SERVICE_EXPOSE@@/${KOMPOSE_SERVICE_EXPOSE}/g' \
      -e 's/@@DIB_KOMPOSE_SERVICE_EXPOSE_TLS_SECRET@@/${KOMPOSE_SERVICE_EXPOSE_TLS_SECRET}/g' \
      -e 's/@@DIB_KOMPOSE_SERVICE_NODEPORT_PORT@@/${KOMPOSE_SERVICE_NODEPORT_PORT}/g' \
      -e 's/@@DIB_APP_BASE_HREF@@/${APP_BASE_HREF}/g' \
      -e 's/@@DIB_APP_DEPLOY_URL@@/${APP_DEPLOY_URL}/g' \
      -e 's/@@DIB_APP_BUILD_CONFIGURATION@@/${APP_BUILD_CONFIGURATION}/g' \
      -e 's/@@DIB_APP_REPO@@/${APP_REPO}/g' \
      -e 's/@@DIB_APP_NPM_BUILD_COMMAND_DELIMITER@@/${APP_NPM_BUILD_COMMAND_DELIMITER}/g' '$docker_compose_template' 1> '$docker_compose_out'
    "
  fi
}

function update_env_file() {  
  local env_file="$1" changed_env_file="$2" original_env_file="$3" symlinked_env_file="$4"
  
  if [[ -s "$changed_env_file" ]]
  then
    run_as "$DOCKER_USER" "
    cp $changed_env_file $original_env_file 2> /dev/null
    cp $changed_env_file $env_file 2> /dev/null
    [[ -h '$symlinked_env_file' ]] || ln -s $env_file $symlinked_env_file 2> /dev/null
  "
  else
    run_as "$DOCKER_USER" "
    test -f $changed_env_file || \
      touch $changed_env_file && cp $changed_env_file $env_file && ln -s $env_file $symlinked_env_file
  "
  fi
}

function detect_file_changed() {
  local original_file="$1" changed_file="$2"

  if [[ "$(diff $original_file $changed_file 2> /dev/null| wc -l)" -ne 0 ]]
  then
    return 0
  fi

  return 1
}

function abort_build_process() {
  msg 'docker image build process aborted'
  exit 1
}

function create_default_directories_if_not_exist() {
  run_as "$DOCKER_USER" "
  defaultDirs=(
    ${DOCKER_APP_BUILD_DEST}
    ${DOCKER_APP_CONFIG_DIR}
    ${DOCKER_APP_COMPOSE_DIR}
    ${DOCKER_APP_COMPOSE_K8S_DIR}
    ${DOCKER_APP_KEYSTORES_SRC}
    ${MAVEN_WRAPPER_PROPERTIES_SRC}
    ${DOCKER_APP_K8S_ANNOTATIONS_DIR}
    ${DOCKER_APP_COMMON_ENV_DIR}
    ${DOCKER_APP_PROJECT_ENV_DIR}
    ${DOCKER_APP_SERVICE_ENV_DIR}
  )

  for defaultDir in \${defaultDirs[@]}
  do
    [[ ! -d \"\$defaultDir\" ]] && mkdir -p \"\$defaultDir\"
  done
"
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
      run_as "$DOCKER_USER" "cp $DOCKER_APP_BUILD_DEST/Dockerfile-spa $DOCKERFILE"
    ;;
    universal)
      run_as "$DOCKER_USER" "cp $DOCKER_APP_BUILD_DEST/Dockerfile-universal $DOCKERFILE"
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
    development) app_image_tag="dev-${app_image_tag}";;
    staging) app_image_tag="staging-${app_image_tag}";;
    beta) app_image_tag="beta-${app_image_tag}";;
    production) app_image_tag="prod-${app_image_tag}";;
    demo) app_image_tag="demo-${app_image_tag}";;
    alpha) app_image_tag="alpha-${app_image_tag}";;
    *) app_image_tag="${app_image_tag}";;
  esac

  printf '%s' $app_image_tag
}

function kubernetes_resources_annotations_changed() {
  local changed_kubernetes_resources_annotations=$DOCKER_APP_K8S_ANNOTATIONS_DIR/*changed
  local original_kubernetes_resources_annotations=$DOCKER_APP_K8S_ANNOTATIONS_DIR/*original
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
  
  if detect_file_changed "$original_env_file" "$changed_env_file" || [[ ! -e "$symlinked_env_file" ]]
  then
    update_env_file "$env_file" "$changed_env_file" "$original_env_file" "$symlinked_env_file"
    return 0
  fi

  return 1
}

function app_project_env_file_changed() {
  local env_file=$DOCKER_APP_PROJECT_ENV_DIR/project.env
  local original_env_file=$DOCKER_APP_PROJECT_ENV_DIR/project.env.original
  local symlinked_env_file=$DOCKER_APP_COMPOSE_DIR/${APP_PROJECT}-${APP_FRAMEWORK}-project.env
  local changed_env_file="$DOCKER_APP_PROJECT_ENV_CHANGED_FILE"
  
  return $(env_file_changed "$env_file" "$original_env_file" "$changed_env_file" "$symlinked_env_file")
}

function app_common_env_file_changed() {
  local env_file=$DOCKER_APP_COMMON_ENV_DIR/common.env
  local original_env_file=$DOCKER_APP_COMMON_ENV_DIR/common.env.original
  local symlinked_env_file=$DOCKER_APP_COMPOSE_DIR/${APP_PROJECT}-${APP_FRAMEWORK}-${APP_ENVIRONMENT}-common.env
  local changed_env_file="$DOCKER_APP_COMMON_ENV_CHANGED_FILE"
  
  return $(env_file_changed "$env_file" "$original_env_file" "$changed_env_file" "$symlinked_env_file")
}

function app_service_env_file_changed() {
  local env_file=$DOCKER_APP_SERVICE_ENV_DIR/service.env
  local original_env_file=$DOCKER_APP_SERVICE_ENV_DIR/service.env.original
  local symlinked_env_file=$DOCKER_APP_COMPOSE_DIR/${APP_IMAGE}-service.env
  local changed_env_file="$DOCKER_APP_SERVICE_ENV_CHANGED_FILE"
  
  return $(env_file_changed "$env_file" "$original_env_file" "$changed_env_file" "$symlinked_env_file")
}

function app_env_file_changed() {
  local env_file=$DOCKER_APP_COMPOSE_DIR/app.env
  local original_env_file=$DOCKER_APP_COMPOSE_DIR/app.env.original
  local symlinked_env_file=$DOCKER_APP_COMPOSE_DIR/${APP_IMAGE}-app.env
  local changed_env_file="$DOCKER_APP_ENV_CHANGED_FILE"
  
  return $(env_file_changed "$env_file" "$original_env_file" "$changed_env_file" "$symlinked_env_file")
}

function check_app_dependencies() {
  if [[ -x "$DOCKER_CMD" ]] 
  then
    msg 'docker already installed successfully.'
  else
    msg '
    Oops, docker command not found! 
    Please install and continue since this command helps you to build and push your Docker images
    '
  fi

  if [[ -x "$DOCKER_COMPOSE_CMD" ]] 
  then
    msg 'docker-compose installed successfully.'
  else
    msg '
    Oops, docker-compose command not found! 
    Please install and continue since this command helps you to build and run your Docker images collectively
  '
  fi

  if [[ -x "$KOMPOSE_CMD" ]]
  then
    msg 'kompose already installed successfully.'
  else
    msg '
    Oops, kompose command not found! 
    Please install and continue since this command helps you to convert your docker-compose files to Kubernetes manifests.
    '
  fi

  if [[ -x "$KUBECTL_CMD" ]] 
  then
    msg 'kubectl already installed successfully.'
  else
    msg '
    Oops, kubectl command not found! 
    Please install and continue since this command helps you to interact with the apiserver 
    inside your Kubernetes master node for various kubernetes operations 
    such as doing deployments, querying the state of your clusters and more.
    '
  fi

  if [[ -x "$NANO_CMD" ]] 
  then
    msg 'nano already installed successfully.'
  else
    msg '
    Oops, nano command not found! 
    Please install and continue since this command helps you to edit some files as your default editor.'
  fi
}

## -- finish
