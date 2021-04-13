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
      ensure_paths_exist "$DIB_APP_CONFIG_COMPOSE_TEMPLATE_FILE $DIB_APP_CONFIG_RUN_SCRIPT"
      copy_docker_build_files "$DIB_APP_DOCKER_COMPOSE_BUILD_FILES" "$DIB_APP_BUILD_DEST"
      build_angular_docker_image
    ;;
    react)
      ensure_paths_exist "$DIB_APP_CONFIG_COMPOSE_TEMPLATE_FILE $DIB_APP_CONFIG_RUN_SCRIPT"
      copy_docker_build_files "$DIB_APP_DOCKER_COMPOSE_BUILD_FILES" "$DIB_APP_BUILD_DEST"
      build_react_docker_image
    ;;
    flask)
      copy_docker_build_files "$DIB_APP_DOCKER_BUILD_FILES" "$DIB_APP_BUILD_DEST"
      build_flask_docker_image
    ;;
    nuxt)
      ensure_paths_exist "$DIB_APP_CONFIG_COMPOSE_TEMPLATE_FILE $DIB_APP_CONFIG_RUN_SCRIPT"
      copy_docker_build_files "$DIB_APP_DOCKER_COMPOSE_BUILD_FILES" "$DIB_APP_BUILD_DEST"
      build_nuxt_docker_image
    ;;
    next)
      ensure_paths_exist "$DIB_APP_CONFIG_COMPOSE_TEMPLATE_FILE $DIB_APP_CONFIG_RUN_SCRIPT"
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

## -- finish
