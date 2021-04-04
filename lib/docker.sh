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

buildSpringbootDockerImage ()
{
  local applicationProperties="$1"
  local springbootProfile="spring.profiles.active=docker"
  local dockerFile="$DOCKERFILE"
  local targetImage="$APP_IMAGE:$APP_IMAGE_TAG"
  local imageBuildStatus=0

  msg 'Building springboot docker image ...'

  testDockerfile=$(runAs "$DOCKER_USER" "test -f $dockerFile; echo -ne \$?")

  if [[ "$testDockerfile" != "0" ]]
  then
    msg 'no Dockerfile found'
    exit 1
  fi

  addMavenWrapperProperties "$MAVEN_WRAPPER_PROPERTIES_SRC" "$MAVEN_WRAPPER_PROPERTIES_DEST"
  addSpringbootKeystores "$dockerFile" "$DOCKER_APP_KEYSTORES_SRC" "$DOCKER_APP_KEYSTORES_DEST"

  runAs "$DOCKER_USER" "
  sed -i 's/^spring\.profiles\.active\=.*/$springbootProfile/g' $applicationProperties
  $DOCKER_CMD build -t'$targetImage' $DOCKER_APP_BUILD_DEST
  exit \$?
" || imageBuildStatus=1

  runAs "$DOCKER_USER" "cp -a $SPRINGBOOT_BASE_APPLICATION_PROPERTIES $SPRINGBOOT_APPLICATION_PROPERTIES_DIR 2> /dev/null"

  return "$imageBuildStatus"
}

buildDockerImageFromComposeFile ()
{
  local dockerFile="$DOCKERFILE"
  local dockerComposeFile="$DOCKER_APP_BUILD_DEST/docker-compose.yml"
  local targetImage="$APP_IMAGE:$APP_IMAGE_TAG"
  local imageBuildStatus=0

  runAs "$DOCKER_USER" "
  if [[ ! -f \"$dockerFile\" ]]
  then
    echo $COMMAND: no Dockerfile found
    exit 1
  fi

  if [[ ! -f \"$dockerComposeFile\" ]]
  then
    echo $COMMAND: no docker compose file found
    exit 1
  fi

  exit 0
" || exit 1

  runAs "$DOCKER_USER" "$DOCKER_COMPOSE_CMD -f $dockerComposeFile build; exit \$?" || imageBuildStatus=1

  return "$imageBuildStatus"
}

buildDockerImageFromFile ()
{
  local dockerFile="$DOCKERFILE"
  local targetImage="$APP_IMAGE:$APP_IMAGE_TAG"
  local imageBuildStatus=0

  runAs "$DOCKER_USER" "
  if [[ ! -f \"$dockerFile\" ]]
  then
    echo $COMMAND: no Dockerfile found
    exit 1
  fi

  exit 0
" || exit 1

  runAs "$DOCKER_USER" " 
  $DOCKER_CMD build -t'$targetImage' $DOCKER_APP_BUILD_DEST
  exit \$?
  " || imageBuildStatus=1

  return "$imageBuildStatus"
}

buildAngularDockerImage ()
{
  msg 'Building angular docker image ...'
  buildDockerImageFromComposeFile
}

buildReactDockerImage ()
{
  msg 'Building react docker image ...'
  buildDockerImageFromComposeFile
}

buildFlaskDockerImage ()
{
  msg 'Building flask docker image ...'
  buildDockerImageFromFile
}

buildNuxtDockerImage ()
{
  msg 'Building nuxt docker image ...'
  buildDockerImageFromComposeFile
}

buildNextDockerImage ()
{
  msg 'Building next docker image ...'
  buildDockerImageFromComposeFile
}

buildFeathersDockerImage ()
{
  msg 'Building feathers docker image ...'
  buildDockerImageFromFile
}

buildExpressDockerImage ()
{
  msg 'Building express docker image ...'
  buildDockerImageFromFile
}

buildMuxDockerImage ()
{
  msg 'Building mux docker image ...'
  buildDockerImageFromFile
}

buildDockerImage ()
{
  case "$APP_FRAMEWORK" in
    springboot)
      buildSpringbootDockerImage "$SPRINGBOOT_APPLICATION_PROPERTIES_DIR/application.properties"
    ;;
    angular)
      buildAngularDockerImage
    ;;
    react)
      buildReactDockerImage
    ;;
    flask)
      buildFlaskDockerImage
    ;;
    nuxt)
      buildNuxtDockerImage
    ;;
    next)
      buildNextDockerImage
    ;;
    feathers)
      buildFeathersDockerImage
    ;;
    express)
      buildExpressDockerImage
    ;;
    mux)
      buildMuxDockerImage
    ;;
    *)
      msg "$APP_FRAMEWORK unknown"
      exit 1
    ;;
  esac
}

pushDockerImage ()
{
  local targetImage="$APP_IMAGE:$APP_IMAGE_TAG"
  local remoteTargetImage="$CONTAINER_REGISTRY/$APP_PROJECT/$targetImage"

  msg 'Pushing docker image ...'

  runAs "$DOCKER_USER" "
  $DOCKER_CMD logout
  $DOCKER_CMD login --username '$DOCKER_LOGIN_USERNAME' --password-stdin < '$DOCKER_LOGIN_PASSWORD' '$CONTAINER_REGISTRY'
  $DOCKER_CMD tag '$targetImage' '$remoteTargetImage'
  $DOCKER_CMD push '$remoteTargetImage'
  $DOCKER_CMD logout
"
}

## -- finish
