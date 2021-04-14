#!/bin/bash
#
# File: docker.sh -> common docker operations
#
# (c) 2021 Frederick Ofosu-Darko <fofosudarko@gmail.com>
#
# Usage: source docker.sh
#
#

## - start here

function build_springboot_docker_image() {
  local docker_file="$DOCKER_FILE"
  local target_image="$APP_IMAGE:$APP_IMAGE_TAG"
  local image_build_status=0

  msg 'Building springboot docker image ...'

  if [[ ! -f "$docker_file" ]]
  then
    msg 'no Dockerfile found'
    exit 1
  fi

  add_springboot_application_properties
  add_maven_wrapper_properties "$MAVEN_WRAPPER_PROPERTIES_SRC" "$MAVEN_WRAPPER_PROPERTIES_DEST"
  add_springboot_keystores "$docker_file" "$DIB_APP_KEYSTORES_SRC" "$DIB_APP_KEYSTORES_DEST"

  $DOCKER_CMD build -t "$target_image" $DIB_APP_BUILD_DEST

  return "$?"
}

function build_docker_image_from_compose_file() {
  local docker_file="$DOCKER_FILE"
  local docker_compose_file="$DIB_APP_BUILD_DEST/docker-compose.yml"
  local target_image="$APP_IMAGE:$APP_IMAGE_TAG"
  local image_build_status=0

  if [[ ! -f "$docker_file" ]]
  then
    echo No Dockerfile found
    exit 1
  fi

  if [[ ! -f "$docker_compose_file" ]]
  then
    echo No docker-compose file found
    exit 1
  fi

  $DOCKER_COMPOSE_CMD -f $docker_compose_file build

  return "$?"
}

function build_docker_image_from_file() {
  local docker_file="$DOCKER_FILE"
  local target_image="$APP_IMAGE:$APP_IMAGE_TAG"
  local image_build_status=0

  if [[ ! -f "$docker_file" ]]
  then
    echo No Dockerfile found
    exit 1
  fi

  $DOCKER_CMD build -t "$target_image" $DIB_APP_BUILD_DEST

  return "$?"
}

function build_angular_docker_image() {
  msg 'Building angular docker image ...'
  build_docker_image_from_compose_file
}

function build_react_docker_image() {
  msg 'Building react docker image ...'
  build_docker_image_from_compose_file
}

function build_flask_docker_image() {
  msg 'Building flask docker image ...'
  build_docker_image_from_file
}

function build_nuxt_docker_image() {
  msg 'Building nuxt docker image ...'
  build_docker_image_from_compose_file
}

function build_next_docker_image() {
  msg 'Building next docker image ...'
  build_docker_image_from_compose_file
}

function build_feathers_docker_image() {
  msg 'Building feathers docker image ...'
  build_docker_image_from_file
}

function build_express_docker_image() {
  msg 'Building express docker image ...'
  build_docker_image_from_file
}

function build_mux_docker_image() {
  msg 'Building mux docker image ...'
  build_docker_image_from_file
}

function build_docker_image() {
  copy_config_files "$DIB_APP_CONFIG_DIR" "$DIB_APP_BUILD_DEST"
  
  case "$APP_FRAMEWORK" in
    springboot)
      ensure_paths_exist "$SPRINGBOOT_APPLICATION_PROPERTIES $MAVEN_WRAPPER_PROPERTIES_SRC"
      copy_docker_build_files "$DIB_APP_DOCKER_BUILD_FILES" "$DIB_APP_BUILD_DEST"
      build_springboot_docker_image
    ;;
    angular)
      ensure_paths_exist "$DIB_APP_CONFIG_DOCKER_COMPOSE_TEMPLATE_FILE $DIB_APP_CONFIG_RUN_SCRIPT"
      copy_docker_build_files "$DIB_APP_DOCKER_COMPOSE_BUILD_FILES" "$DIB_APP_BUILD_DEST"
      build_angular_docker_image
    ;;
    react)
      ensure_paths_exist "$DIB_APP_CONFIG_DOCKER_COMPOSE_TEMPLATE_FILE $DIB_APP_CONFIG_RUN_SCRIPT"
      copy_docker_build_files "$DIB_APP_DOCKER_COMPOSE_BUILD_FILES" "$DIB_APP_BUILD_DEST"
      build_react_docker_image
    ;;
    flask)
      copy_docker_build_files "$DIB_APP_DOCKER_BUILD_FILES" "$DIB_APP_BUILD_DEST"
      build_flask_docker_image
    ;;
    nuxt)
      ensure_paths_exist "$DIB_APP_CONFIG_DOCKER_COMPOSE_TEMPLATE_FILE $DIB_APP_CONFIG_RUN_SCRIPT"
      copy_docker_build_files "$DIB_APP_DOCKER_COMPOSE_BUILD_FILES" "$DIB_APP_BUILD_DEST"
      build_nuxt_docker_image
    ;;
    next)
      ensure_paths_exist "$DIB_APP_CONFIG_DOCKER_COMPOSE_TEMPLATE_FILE $DIB_APP_CONFIG_RUN_SCRIPT"
      copy_docker_build_files "$DIB_APP_DOCKER_COMPOSE_BUILD_FILES" "$DIB_APP_BUILD_DEST"
      build_next_docker_image
    ;;
    feathers)
      copy_docker_build_files "$DIB_APP_DOCKER_BUILD_FILES" "$DIB_APP_BUILD_DEST"
      build_feathers_docker_image
    ;;
    express)
      copy_docker_build_files "$DIB_APP_DOCKER_BUILD_FILES" "$DIB_APP_BUILD_DEST"
      build_express_docker_image
    ;;
    mux)
      copy_docker_build_files "$DIB_APP_DOCKER_BUILD_FILES" "$DIB_APP_BUILD_DEST"
      build_mux_docker_image
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

function columnize_items() {
  echo -ne "$1" | sed -E -e 's/[[:space:]]+//g' -e 's/,/\n/g' | grep -vE '^$' | grep -vE '^\s+$'
}

function run_docker_container() {

  function get_app_ports() {
    if [[ -n "$DIB_APP_PORTS" ]]
    then
      while read -r port
      do
        ports="-p $port:$port $ports"
      done < <(columnize_items "$DIB_APP_PORTS")
    fi
  }

  function get_app_env_files() {
    if [[ -n "$DIB_APP_ENV_FILES" ]]
    then
      while read -r env_file
      do
        case "$env_file"
        in
          app-env)
            [[ -s "$DIB_APP_ENV_CHANGED_FILE" ]] && env_files="--env-file $DIB_APP_ENV_CHANGED_FILE $env_files"
          ;;
          service-env)
            [[ -s "$DIB_APP_SERVICE_ENV_CHANGED_FILE" ]] && env_files="--env-file $DIB_APP_SERVICE_ENV_CHANGED_FILE $env_files"
          ;;
          common-env)
            [[ -s "$DIB_APP_COMMON_ENV_CHANGED_FILE" ]] && env_files="--env-file $DIB_APP_COMMON_ENV_CHANGED_FILE $env_files"
          ;;
          project-env)
            [[ -s "$DIB_APP_PROJECT_ENV_CHANGED_FILE" ]] && env_files="--env-file $DIB_APP_PROJECT_ENV_CHANGED_FILE $env_files"
          ;;
        esac
      done < <(columnize_items "$DIB_APP_ENV_FILES")
    fi
  }

  function save_data_to_root_cache_on_run() {
    save_data_to_root_cache
  }

  local ports= env_files= target_image="$APP_IMAGE:$APP_IMAGE_TAG"

  msg 'Running docker container ...'

  get_app_ports
  get_app_env_files

  if is_docker_container_running
  then
    if [[ "$DIB_APP_CONTAINERS_RESTART" == "1" ]]
    then
      $DOCKER_CMD container stop $APP_IMAGE
      $DOCKER_CMD container rm -f $APP_IMAGE
      $DOCKER_CMD run --detach --name $APP_IMAGE $ports $env_files $target_image
    else
      $DOCKER_CMD container restart $APP_IMAGE
    fi
  elif is_docker_container_dead || is_docker_container_exited || is_docker_container_paused
  then
    $DOCKER_CMD container rm -f $APP_IMAGE
    $DOCKER_CMD run --detach --name $APP_IMAGE $ports $env_files $target_image
  else
    $DOCKER_CMD run --detach --name $APP_IMAGE $ports $env_files $target_image
  fi

  save_data_to_root_cache_on_run
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
