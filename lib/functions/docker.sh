#!/bin/bash
#
# File: docker.sh -> common docker operations
#
# Usage: source docker.sh
#
#

## - start here

function copy_docker_build_files() { 
  local build_files="$1" docker_project="$2"
  
  msg 'Copying docker build files ...'

  ensure_paths_exist "$docker_project"
  format_docker_compose_template "$DIB_APP_CONFIG_DOCKER_COMPOSE_TEMPLATE_FILE" "$DIB_APP_CONFIG_DOCKER_COMPOSE_FILE"
  rsync -av --exclude='*.template*' --exclude='*.copy' $build_files $docker_project 2> /dev/null
}

function format_docker_compose_template() {
  local docker_compose_template="$1" docker_compose_out="$2"
  
  if [[ -s "$docker_compose_template" ]]
  then
    sed -e "s/{{DIB_APP_IMAGE}}/${APP_IMAGE}/g" \
    -e "s/{{DIB_APP_PROJECT}}/${APP_PROJECT}/g" \
    -e "s/{{DIB_APPS_CONTAINER_REGISTRY}}/${APPS_CONTAINER_REGISTRY}/g" \
    -e "s/{{DIB_APP_IMAGE_TAG}}/${APP_IMAGE_TAG}/g" \
    -e "s/{{DIB_APP_ENVIRONMENT}}/${APP_ENVIRONMENT}/g" \
    -e "s/{{DIB_APP_FRAMEWORK}}/${APP_FRAMEWORK}/g" \
    -e "s/{{DIB_APP_PACKAGER_BUILD_COMMANDS}}/${APP_PACKAGER_BUILD_COMMANDS}/g" \
    -e "s/{{DIB_KOMPOSE_IMAGE_PULL_SECRET}}/${KOMPOSE_IMAGE_PULL_SECRET}/g" \
    -e "s/{{DIB_KOMPOSE_IMAGE_PULL_POLICY}}/${KOMPOSE_IMAGE_PULL_POLICY}/g" \
    -e "s/{{DIB_KOMPOSE_SERVICE_TYPE}}/${KOMPOSE_SERVICE_TYPE}/g" \
    -e "s/{{DIB_KOMPOSE_SERVICE_EXPOSE}}/${KOMPOSE_SERVICE_EXPOSE}/g" \
    -e "s/{{DIB_KOMPOSE_SERVICE_EXPOSE_TLS_SECRET}}/${KOMPOSE_SERVICE_EXPOSE_TLS_SECRET}/g" \
    -e "s/{{DIB_KOMPOSE_SERVICE_NODEPORT_PORT}}/${KOMPOSE_SERVICE_NODEPORT_PORT}/g" \
    -e "s/{{DIB_APP_BASE_HREF}}/${APP_BASE_HREF//\//\\/}/g" \
    -e "s/{{DIB_APP_DEPLOY_URL}}/${APP_DEPLOY_URL//\//\\/}/g" \
    -e "s/{{DIB_APP_BUILD_CONFIGURATION}}/${APP_BUILD_CONFIGURATION}/g" \
    -e "s/{{DIB_APP_REPO}}/${APP_REPO}/g" \
    -e "s/{{DIB_APP_PACKAGER_BUILD_COMMAND_DELIMITER}}/${APP_PACKAGER_BUILD_COMMAND_DELIMITER}/g" \
    -e "s/{{DIB_DOCKER_COMPOSE_NETWORK_MODE}}/${DOCKER_COMPOSE_NETWORK_MODE}/g" \
    -e "s/{{DIB_DOCKER_COMPOSE_DEPLOY_REPLICAS}}/${DOCKER_COMPOSE_DEPLOY_REPLICAS}/g" \
    -e "s/{{DIB_APP_PORT}}/${APP_PORT}/g" \
    -e "s/{{DIB_APP_RUN_APP_ENV_FILE}}/${DIB_APP_ENV_CHANGED_FILE//\//\\/}/g" \
    -e "s/{{DIB_APP_RUN_SERVICE_ENV_FILE}}/${DIB_APP_SERVICE_ENV_CHANGED_FILE//\//\\/}/g" \
    -e "s/{{DIB_APP_RUN_COMMON_ENV_FILE}}/${DIB_APP_COMMON_ENV_CHANGED_FILE//\//\\/}/g" \
    -e "s/{{DIB_APP_RUN_PROJECT_ENV_FILE}}/${DIB_APP_PROJECT_ENV_CHANGED_FILE//\//\\/}/g" \
      "$docker_compose_template" 1> "$docker_compose_out"
  else
    [[ ! -f "$docker_compose_out" ]] && touch "$docker_compose_out"
  fi
}

function select_docker_build_process() {
  if [[ -s "$DIB_APP_CONFIG_DOCKER_COMPOSE_TEMPLATE_FILE" ]]
  then
    build_docker_image_from_compose_file
  else
    build_docker_image_from_file
  fi
}

function build_docker_image_from_compose_file() {
  local target_image="$APP_IMAGE:$APP_IMAGE_TAG"

  if [[ ! -f "$DOCKER_COMPOSE_FILE" ]]
  then
    echo No docker-compose file found
    exit 1
  fi

  if [[ ! -f "$DOCKER_FILE" ]]
  then
    echo No Dockerfile found
    exit 1
  fi

  $DOCKER_COMPOSE_CMD -f $DOCKER_COMPOSE_FILE build

  return "$?"
}

function build_docker_image_from_file() {
  local target_image="$APP_IMAGE:$APP_IMAGE_TAG"

  if [[ ! -f "$DOCKER_FILE" ]]
  then
    echo No Dockerfile found
    exit 1
  fi

  $DOCKER_CMD build -t "$target_image" $DIB_APP_BUILD_DEST

  return "$?"
}

function build_docker_image() {
  create_directory_if_not_exist "$MAVEN_WRAPPER_PROPERTIES_SRC"
  copy_config_files "$DIB_APP_CONFIG_DIR" "$DIB_APP_BUILD_DEST"
  copy_docker_build_files "$DIB_APP_CONFIG_DOCKER_FILE $DIB_APP_CONFIG_DOCKER_COMPOSE_FILE" "$DIB_APP_BUILD_DEST"
  
  case "$APP_FRAMEWORK" in
    spring)
      msg 'Building spring docker image ...'
      
      ensure_paths_exist "$SPRING_APPLICATION_PROPERTIES"
      add_spring_application_properties
      add_maven_wrapper_properties "$MAVEN_WRAPPER_PROPERTIES_SRC" "$MAVEN_WRAPPER_PROPERTIES_DEST"
      add_spring_keystores "$DOCKER_FILE" "$DIB_APP_KEYSTORES_SRC" "$DIB_APP_KEYSTORES_DEST"
      select_docker_build_process
    ;;
    angular)
      msg 'Building angular docker image ...'
      select_docker_build_process
    ;;
    react)
      msg 'Building react docker image ...'
      select_docker_build_process
    ;;
    flask)
      msg 'Building flask docker image ...'
      select_docker_build_process
    ;;
    nuxt)
      msg 'Building nuxt docker image ...'
      select_docker_build_process
    ;;
    next)
      msg 'Building next docker image ...'
      select_docker_build_process
    ;;
    feathers)
      msg 'Building feathers docker image ...'
      select_docker_build_process
    ;;
    express)
      msg 'Building express docker image ...'
      select_docker_build_process
    ;;
    mux)
      msg 'Building mux docker image ...'
      select_docker_build_process
    ;;
    rails)
      msg 'Building rails docker image ...'
      select_docker_build_process
    ;;
    django)
      msg 'Building django docker image ...'
      select_docker_build_process
    ;;
    hugo)
      msg 'Building hugo docker image ...'
      select_docker_build_process
    ;;
    jekyll)
      msg 'Building jekyll docker image ...'
      select_docker_build_process
    ;;
    gatsby)
      msg 'Building gatsby docker image ...'
      select_docker_build_process
    ;;
    dotnet)
      msg 'Building dotnet docker image ...'
      select_docker_build_process
    ;;
    vue)
      msg 'Building vue docker image ...'
      select_docker_build_process
    ;;
    laravel)
      msg 'Building laravel docker image ...'
      select_docker_build_process
    ;;
    redwood)
      msg 'Building redwood docker image ...'
      select_docker_build_process
    ;;
    *)
      msg "$APP_FRAMEWORK unknown"
      exit 1
    ;;
  esac
}

function push_docker_image() {
  local target_image="$APP_IMAGE:$APP_IMAGE_TAG"
  local remote_target_image="$DIB_APPS_CONTAINER_REGISTRY/$APP_PROJECT/$target_image"

  msg 'Pushing docker image ...'

  ensure_paths_exist "$DOCKER_LOGIN_PASSWORD"

  $DOCKER_CMD logout 2> /dev/null
  $DOCKER_CMD login --username "$DOCKER_LOGIN_USERNAME" --password-stdin < "$DOCKER_LOGIN_PASSWORD" "$DIB_APPS_CONTAINER_REGISTRY"
  $DOCKER_CMD tag "$target_image" "$remote_target_image"
  $DOCKER_CMD push "$remote_target_image"
  $DOCKER_CMD logout 2> /dev/null
}

function is_docker_container_running() {
  local result=$($DOCKER_CMD container ps --filter "name=${APP_IMAGE}" --filter "status=running" -q)
  [[ -n "$result" ]] && return 0 || return 1
}

function is_docker_container_dead() {
  local result=$($DOCKER_CMD container ps --filter "name=${APP_IMAGE}" --filter "status=dead" -q)
  [[ -n "$result" ]] && return 0 || return 1
}

function is_docker_container_exited() {
  local result=$($DOCKER_CMD container ps --filter "name=${APP_IMAGE}" --filter "status=exited" -q)
  [[ -n "$result" ]] && return 0 || return 1
}

function is_docker_container_paused() {
  local result=$($DOCKER_CMD container ps --filter "name=${APP_IMAGE}" --filter "status=paused" -q)
  [[ -n "$result" ]] && return 0 || return 1
}

function is_docker_image_changed() {
  local latest_image="${APP_IMAGE}:${APP_IMAGE_TAG}"
  local current_image=$($DOCKER_CMD container ps --filter="name=${APP_IMAGE}" --format '{{.Image}}' )
  
  [[ "$current_image" != "$latest_image" ]] && return 0 || return 1
}

function run_docker_container() {

  function save_data_to_cache_on_run() {
    save_data_to_root_cache
    save_data_to_app_cache
  }

  local target_image="$APP_IMAGE:$APP_IMAGE_TAG"

  msg 'Running docker container ...'

  format_docker_compose_template "$DIB_APP_RUN_DOCKER_COMPOSE_TEMPLATE_FILE" "$DIB_APP_RUN_DOCKER_COMPOSE_FILE"
    
  if is_docker_container_running
  then
    if is_docker_image_changed
    then
      $DOCKER_COMPOSE_CMD -f "$DIB_APP_RUN_DOCKER_COMPOSE_FILE" stop
      $DOCKER_COMPOSE_CMD -f "$DIB_APP_RUN_DOCKER_COMPOSE_FILE" rm -f
      $DOCKER_COMPOSE_CMD -f "$DIB_APP_RUN_DOCKER_COMPOSE_FILE" up -d
    else
      $DOCKER_COMPOSE_CMD -f "$DIB_APP_RUN_DOCKER_COMPOSE_FILE" restart
    fi
  elif is_docker_container_dead || is_docker_container_exited || is_docker_container_paused
  then
    $DOCKER_COMPOSE_CMD -f "$DIB_APP_RUN_DOCKER_COMPOSE_FILE" down
    $DOCKER_COMPOSE_CMD -f "$DIB_APP_RUN_DOCKER_COMPOSE_FILE" rm -f
    $DOCKER_COMPOSE_CMD -f "$DIB_APP_RUN_DOCKER_COMPOSE_FILE" up -d
  else
    $DOCKER_COMPOSE_CMD -f "$DIB_APP_RUN_DOCKER_COMPOSE_FILE" up -d
  fi

  save_data_to_cache_on_run
}

function stop_docker_container() {
  msg 'Stopping docker container ...'

  if is_docker_container_running
  then
    $DOCKER_CMD container stop $APP_IMAGE
    $DOCKER_CMD container rm -f $APP_IMAGE
  elif is_docker_container_dead || is_docker_container_exited || is_docker_container_paused
  then
    $DOCKER_CMD container rm -f $APP_IMAGE
  fi
}

function ps_docker_container() {
  msg 'Showing docker container ...'
  $DOCKER_CMD container ps --filter "name=${APP_IMAGE}" --all
}

## -- finish
