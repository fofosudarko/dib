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

function select_docker_build_process() {
  if [[ -s "$DIB_APP_CONFIG_DOCKER_COMPOSE_TEMPLATE_FILE" ]]
  then
    build_docker_image_from_compose_file
  else
    build_docker_image_from_file
  fi
}

function build_docker_image_from_compose_file() {
  local docker_file="$DOCKER_FILE"
  local docker_compose_file="$DIB_APP_BUILD_DEST/docker-compose.yml"
  local target_image="$APP_IMAGE:$APP_IMAGE_TAG"

  if [[ ! -f "$docker_compose_file" ]]
  then
    echo No docker-compose file found
    exit 1
  fi

  if [[ ! -f "$docker_file" ]]
  then
    echo No Dockerfile found
    exit 1
  fi

  $DOCKER_COMPOSE_CMD -f $docker_compose_file build

  return "$?"
}

function build_docker_image_from_file() {
  local docker_file="$DOCKER_FILE"
  local target_image="$APP_IMAGE:$APP_IMAGE_TAG"

  if [[ ! -f "$docker_file" ]]
  then
    echo No Dockerfile found
    exit 1
  fi

  $DOCKER_CMD build -t "$target_image" $DIB_APP_BUILD_DEST

  return "$?"
}

function build_docker_image() {
  copy_config_files "$DIB_APP_CONFIG_DIR" "$DIB_APP_BUILD_DEST"
  copy_docker_build_files "$DIB_APP_DOCKER_BUILD_FILES" "$DIB_APP_BUILD_DEST"
  
  case "$APP_FRAMEWORK" in
    spring)
      msg 'Building spring docker image ...'
      
      ensure_paths_exist "$SPRING_APPLICATION_PROPERTIES $MAVEN_WRAPPER_PROPERTIES_SRC"
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
