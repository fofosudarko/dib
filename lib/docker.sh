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

  check_docker_file=$(run_as "$DOCKER_USER" "test -f $docker_file; echo -ne \$?")

  if [[ "$check_docker_file" != "0" ]]
  then
    msg 'no Dockerfile found'
    exit 1
  fi

  add_springboot_application_properties
  add_maven_wrapper_properties "$MAVEN_WRAPPER_PROPERTIES_SRC" "$MAVEN_WRAPPER_PROPERTIES_DEST"
  add_springboot_keystores "$docker_file" "$DOCKER_APP_KEYSTORES_SRC" "$DOCKER_APP_KEYSTORES_DEST"

  run_as "$DOCKER_USER" "$DOCKER_CMD build -t '$target_image' $DOCKER_APP_BUILD_DEST; exit \$?" || image_build_status=1

  return "$image_build_status"
}

function build_docker_image_from_compose_file() {
  local docker_file="$DOCKER_FILE"
  local docker_compose_file="$DOCKER_APP_BUILD_DEST/docker-compose.yml"
  local target_image="$APP_IMAGE:$APP_IMAGE_TAG"
  local image_build_status=0

  run_as "$DOCKER_USER" "
  if [[ ! -f '$docker_file' ]]
  then
    echo $COMMAND: no Dockerfile found
    exit 1
  fi

  if [[ ! -f '$docker_compose_file' ]]
  then
    echo $COMMAND: no docker compose file found
    exit 1
  fi

  exit 0
" || exit 1

  run_as "$DOCKER_USER" "$DOCKER_COMPOSE_CMD -f $docker_compose_file build; exit \$?" || image_build_status=1

  return "$image_build_status"
}

function build_docker_image_from_file() {
  local docker_file="$DOCKER_FILE"
  local target_image="$APP_IMAGE:$APP_IMAGE_TAG"
  local image_build_status=0

  run_as "$DOCKER_USER" "
  if [[ ! -f '$docker_file' ]]
  then
    echo $COMMAND: no Dockerfile found
    exit 1
  fi

  exit 0
" || exit 1

  run_as "$DOCKER_USER" "$DOCKER_CMD build -t '$target_image' $DOCKER_APP_BUILD_DEST; exit \$?" || image_build_status=1

  return "$image_build_status"
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
  case "$APP_FRAMEWORK" in
    springboot)
      build_springboot_docker_image
    ;;
    angular)
      build_angular_docker_image
    ;;
    react)
      build_react_docker_image
    ;;
    flask)
      build_flask_docker_image
    ;;
    nuxt)
      build_nuxt_docker_image
    ;;
    next)
      build_next_docker_image
    ;;
    feathers)
      build_feathers_docker_image
    ;;
    express)
      build_express_docker_image
    ;;
    mux)
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
  local remote_target_image="$DOCKER_APPS_CONTAINER_REGISTRY/$APP_PROJECT/$target_image"

  msg 'Pushing docker image ...'

  run_as "$DOCKER_USER" "
  $DOCKER_CMD logout 2> /dev/null
  $DOCKER_CMD login --username '$DOCKER_LOGIN_USERNAME' --password-stdin < '$DOCKER_LOGIN_PASSWORD' '$DOCKER_APPS_CONTAINER_REGISTRY'
  $DOCKER_CMD tag '$target_image' '$remote_target_image'
  $DOCKER_CMD push '$remote_target_image'
  $DOCKER_CMD logout 2> /dev/null
"
}

## -- finish
